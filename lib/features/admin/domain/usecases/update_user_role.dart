import 'package:phcl_accounts/features/admin/domain/repositories/user_management_repository.dart';

class UpdateUserRole {
  final UserManagementRepository repository;

  UpdateUserRole(this.repository);

  Future<void> call(String userId, String role) async {
    await repository.updateUserRole(userId, role);
  }
}
