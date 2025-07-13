import 'package:phcl_accounts/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:phcl_accounts/core/errors/unauthorized_failure.dart';

// lib/features/admin/domain/use_cases/create_user_account.dart
class CreateUserAccount {
  final AuthRepositoryImpl _authRepository;

  CreateUserAccount(this._authRepository);

  Future<void> call({
    required String email,
    required String password,
    required String name,
    required String contactNo,
    required String role,
  }) async {
    // Only admin can create accounts
    final currentUser = await _authRepository.getCurrentUser();
    if (currentUser.role != 'admin') {
      throw UnauthorizedFailure( message: 'Only admins can create user accounts.', statusCode: 403);
    }
    
    await _authRepository.signUp(email, password, name, contactNo, role);
  }
}