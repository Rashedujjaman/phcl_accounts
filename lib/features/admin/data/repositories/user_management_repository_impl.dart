import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';
import 'package:phcl_accounts/features/admin/domain/repositories/user_management_repository.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final FirebaseFirestore _firestore;

  UserManagementRepositoryImpl(this._firestore);

  @override
  Stream<List<UserEntity>> getAllUsers() {
    try {
      return _firestore
          .collection('users')
          .snapshots()
          .map((snapshot) {
        final users = <UserEntity>[];
        
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            if (data.isNotEmpty) {
              final user = UserEntity.fromMap(doc.id, data);
              users.add(user);
            }
          } catch (e) {
            continue;
          }
        }
        
        // Sort users by createdAt in Dart instead of Firestore to avoid query issues
        users.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        
        return users;
      }).handleError((error, stackTrace) {

        throw Exception('Failed to fetch users: $error');
      });
    } catch (e) {
      // Return an empty stream instead of throwing
      return Stream.value(<UserEntity>[]);
    }
  }

  @override
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role,
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  @override
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }
}
