import 'package:phcl_accounts/features/auth/domain/repositories/auth_repository.dart';
import 'package:phcl_accounts/core/errors/firebase_auth_failure.dart';

class SignUp {
  final AuthRepository repository;

  SignUp(this.repository);

  Future<void> call(
    String firstName,
    String lastName,
    String contactNo,
    String role,
    String email,
    String password,
  ) async {
    try {
      await repository.signUp(
        firstName,
        lastName,
        contactNo,
        role,
        email,
        password,
      );
    } on FirebaseAuthFailure {
      rethrow;
    } catch (e) {
      throw FirebaseAuthFailure(e.toString());
    }
  }
}