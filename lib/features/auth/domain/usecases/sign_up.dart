import 'package:phcl_accounts/features/auth/domain/repositories/auth_repository.dart';
import 'package:phcl_accounts/core/errors/firebase_auth_failure.dart';

class SignUp {
  final AuthRepository repository;

  SignUp(this.repository);

  Future<void> call(
    String email,
    String password,
    String name,
    String contactNo,
    String role,
  ) async {
    try {
      await repository.signUp(email, password, name, contactNo, role);
    } on FirebaseAuthFailure {
      rethrow;
    } catch (e) {
      throw FirebaseAuthFailure(e.toString());
    }
  }
}