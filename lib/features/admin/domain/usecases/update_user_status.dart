import 'package:phcl_accounts/features/admin/domain/repositories/user_management_repository.dart';

class UpdateUserStatus {
  final UserManagementRepository repository;

  UpdateUserStatus(this.repository);

  Future<void> call(String userId, bool isActive) async {
    await repository.updateUserStatus(userId, isActive);
  }
}
