import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
        final user = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (user.docs.isEmpty) {
          throw const FirebaseAuthFailure('User account not found.');
        }

        final userData = user.docs.first.data();
        final isActive = userData['isActive'] as bool? ?? false;
        
        if (!isActive) {
          // User is deactivated
          throw const FirebaseAuthFailure('Your account has been deactivated. Please contact an administrator for details.');
        }

      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (e) {
      // Check if it's already a FirebaseAuthFailure to preserve our custom messages
      if (e is FirebaseAuthFailure) {
        rethrow;
      }
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
      // Store the current admin user info
      final currentUser = _firebaseAuth.currentUser;
      final currentUserId = currentUser?.uid;
      
      // Create a secondary Firebase app for user creation
      FirebaseApp? secondaryApp;
      FirebaseAuth? secondaryAuth;
      
      try {
        // Try to get existing secondary app or create new one
        try {
          secondaryApp = Firebase.app('UserCreationApp');
        } catch (e) {
          // App doesn't exist, create it
          secondaryApp = await Firebase.initializeApp(
            name: 'UserCreationApp',
            options: Firebase.app().options,
          );
        }
        
        secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        
        // Create the new user using secondary auth (won't affect current session)
        UserCredential userCredential = await secondaryAuth
            .createUserWithEmailAndPassword(email: email, password: password);

        final newUserId = userCredential.user!.uid;
        
        // Create user document in Firestore
        UserEntity user = UserEntity(
          firstName: firstName,
          lastName: lastName,
          contactNo: contactNo,
          role: role,
          email: email,
          imageUrl: '',
          isActive: true,
          createdBy: currentUserId ?? newUserId,
          createdAt: DateTime.now(),
          uid: newUserId,
        );

        await _firestore.collection('users').doc(user.uid).set(user.toMap());
        
        // Sign out from secondary auth
        await secondaryAuth.signOut();
        
        // Current admin session remains intact!
        
      } finally {
        // Clean up secondary app
        if (secondaryApp != null) {
          try {
            await secondaryApp.delete();
          } catch (e) {
            // Ignore cleanup errors
          }
        }
      }
      
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
        throw const FirebaseAuthFailure('User account not found.');
      }

      final userData = doc.data() as Map<String, dynamic>;
      final userEntity = UserEntity.fromMap(doc.id, userData);
      
      // Check if user is still active
      if (userEntity.isActive != true) {
        // User has been deactivated, sign them out
        await _firebaseAuth.signOut();
        throw const FirebaseAuthFailure('Your account has been deactivated. Please contact an administrator.');
      }
      
      return userEntity;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (e) {
      // Check if it's already a FirebaseAuthFailure to preserve our custom messages
      if (e is FirebaseAuthFailure) {
        rethrow;
      }
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
