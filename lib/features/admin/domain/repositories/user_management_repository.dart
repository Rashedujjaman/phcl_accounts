import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';

abstract class UserManagementRepository {
  Stream<List<UserEntity>> getAllUsers();
  Future<void> updateUserRole(String userId, String role);
  Future<void> updateUserStatus(String userId, bool isActive);
}
