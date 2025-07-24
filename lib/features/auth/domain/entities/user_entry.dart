class UserEntity {
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
  
  UserEntity({
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

  factory UserEntity.fromMap(String id,Map<String, dynamic> map) {
    return UserEntity(
      uid: id,
      firstName: map['firstName'],
      lastName: map['lastName'],
      contactNo: map['contactNo'],
      role: map['role'],
      email: map['email'],
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      createdBy: map['createdBy'],
      createdAt: map['createdAt'].toDate(),
    );
  }
}