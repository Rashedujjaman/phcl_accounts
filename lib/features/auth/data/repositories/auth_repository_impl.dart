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
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (_) {
      throw const FirebaseAuthFailure();
    }
  }

  @override
  Future<void> signUp(String email, String password, String name, String contactNo, String role)
  async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserEntity user = UserEntity(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        contactNo: contactNo,
        role: role
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());
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
    User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const FirebaseAuthFailure();
    }

    DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      throw const FirebaseAuthFailure();
    }

    return UserEntity.fromMap(doc.data() as Map<String, dynamic>);
  }

}