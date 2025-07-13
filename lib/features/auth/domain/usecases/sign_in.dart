import 'package:phcl_accounts/features/auth/domain/repositories/auth_repository.dart';
import 'package:phcl_accounts/core/errors/firebase_auth_failure.dart';

class SignIn {
  final AuthRepository repository;

  SignIn(this.repository);

  Future<void> call(String email, String password) async {
    try {
      await repository.signIn(email, password);
    } on FirebaseAuthFailure {
      rethrow;
    } catch (e) {
      throw FirebaseAuthFailure(e.toString());
    }
  }
}