import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart'; 

abstract class AuthRepository {
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password, String name, String contactNo, String role);
  Future<void> signOut();
  Future<bool> isSignedIn();
  Future<UserEntity> getCurrentUser();
}