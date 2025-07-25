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
          .orderBy('createdAt', descending: true)
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
            print('Error parsing user document ${doc.id}: $e');
            // Skip invalid documents but continue processing others
            continue;
          }
        }
        
        return users;
      }).handleError((error, stackTrace) {
        print('Firestore stream error: $error');
        print('Stack trace: $stackTrace');
        throw Exception('Failed to fetch users: $error');
      });
    } catch (e) {
      print('Error setting up Firestore stream: $e');
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
      print('Error updating user role: $e');
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
      print('Error updating user status: $e');
      throw Exception('Failed to update user status: $e');
    }
  }
}
