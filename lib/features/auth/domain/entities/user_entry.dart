import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String? uid;
  final String? firstName;
  final String? lastName;
  final String? contactNo;
  final String? role;
  final String? email;
  final String? imageUrl;
  final bool? isActive;
  final String? createdBy;
  final DateTime? createdAt;
  
  const UserEntity({
    this.uid,
    this.firstName,
    this.lastName,
    this.contactNo,
    this.role,
    this.email,
    this.imageUrl,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        uid,
        firstName,
        lastName,
        contactNo,
        role,
        email,
        imageUrl,
        isActive,
        createdBy,
        createdAt,
      ];

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'contactNo': contactNo,
      'role': role,
      'email': email,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserEntity.fromMap(String id, Map<String, dynamic> map) {
    try {
      // Handle createdAt safely
      DateTime? createdAt;
      final createdAtField = map['createdAt'];
      if (createdAtField != null) {
        if (createdAtField is Timestamp) {
          createdAt = createdAtField.toDate();
        } else if (createdAtField is String) {
          createdAt = DateTime.tryParse(createdAtField);
        } else if (createdAtField is int) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtField);
        }
      }

      return UserEntity(
        uid: id,
        firstName: map['firstName']?.toString(),
        lastName: map['lastName']?.toString(),
        contactNo: map['contactNo']?.toString(),
        role: map['role']?.toString() ?? 'user',
        email: map['email']?.toString(),
        imageUrl: map['imageUrl']?.toString(),
        isActive: map['isActive'] ?? true,
        createdBy: map['createdBy']?.toString(),
        createdAt: createdAt,
      );
    } catch (e) {
      // Return a minimal valid entity if parsing fails
      return UserEntity(
        uid: id,
        firstName: 'Unknown',
        lastName: 'User',
        email: 'unknown@example.com',
        role: 'user',
        isActive: false,
        createdAt: DateTime.now(),
      );
    }
  }
}