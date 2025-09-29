import 'dart:io';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';
import 'package:phcl_accounts/features/auth/domain/repositories/auth_repository.dart';
import 'package:phcl_accounts/core/errors/firebase_auth_failure.dart';

class UpdateUserProfile {
  final AuthRepository repository;

  UpdateUserProfile(this.repository);

  Future<UserEntity> call({
    required String userId,
    String? firstName,
    String? lastName,
    String? contactNo,
    File? profileImage,
  }) async {
    try {
      return await repository.updateUserProfile(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        contactNo: contactNo,
        profileImage: profileImage,
      );
    } on FirebaseAuthFailure {
      rethrow;
    } catch (e) {
      throw FirebaseAuthFailure(e.toString());
    }
  }
}
