import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:phcl_accounts/features/auth/domain/repositories/auth_repository.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';
import 'package:phcl_accounts/core/errors/firebase_auth_failure.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _storage = storage;

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (_) {
      throw const FirebaseAuthFailure();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (_) {
      throw const FirebaseAuthFailure();
    }
  }

  @override
  Future<void> signUp(
    String firstName,
    String lastName,
    String contactNo,
    String role,
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      UserEntity user = UserEntity(
        firstName: firstName,
        lastName: lastName,
        contactNo: contactNo,
        role: role,
        email: email,
        imageUrl: '',
        isActive: true,
        createdBy: userCredential.user!.uid,
        createdAt: DateTime.now(),
        uid: _firebaseAuth.currentUser?.uid,
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (_) {
      throw const FirebaseAuthFailure();
    }
  }

  @override
  Future<bool> isSignedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const FirebaseAuthFailure();
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        throw const FirebaseAuthFailure();
      }

      return UserEntity.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseAuthFailure.fromCode(e.toString());
    }
  }

  @override
  Future<UserEntity> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? contactNo,
    File? profileImage,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (contactNo != null) updateData['contactNo'] = contactNo;
      
      // Handle profile image upload
      if (profileImage != null) {
        final imageUrl = await _uploadProfileImage(userId, profileImage);
        updateData['imageUrl'] = imageUrl;
      }
      
      // Update Firestore document
      await _firestore.collection('users').doc(userId).update(updateData);
      
      // Return updated user
      return await getCurrentUser();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseAuthFailure.fromCode(e.toString());
    }
  }
  
  Future<String> _uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw FirebaseAuthFailure('Failed to upload profile image: $e');
    }
  }
}
