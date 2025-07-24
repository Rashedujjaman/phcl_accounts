import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart'; 

abstract class AuthRepository {
  Future<void> signIn(String email, String password);
  Future<void> signUp(
    String firstName,
    String lastName,
    String contactNo,
    String role,
    String email,
    String password,
  );
  Future<void> signOut();
  Future<bool> isSignedIn();
  Future<UserEntity> getCurrentUser();
}