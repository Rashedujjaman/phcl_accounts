import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';
import 'package:phcl_accounts/features/admin/domain/repositories/user_management_repository.dart';

class GetAllUsers {
  final UserManagementRepository repository;

  GetAllUsers(this.repository);

  Stream<List<UserEntity>> call() {
    return repository.getAllUsers();
  }
}
