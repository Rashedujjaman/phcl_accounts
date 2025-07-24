import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phcl_accounts/features/auth/domain/repositories/auth_repository.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';
import 'package:phcl_accounts/core/errors/firebase_auth_failure.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

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
}
