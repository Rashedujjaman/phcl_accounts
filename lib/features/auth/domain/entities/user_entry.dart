class UserEntity {
  final String? uid;
  final String? email;
  final String? name;
  final String? role;
  final String? contactNo;
  
  UserEntity({
    this.uid,
    this.email,
    this.name,
    this.role,
    this.contactNo,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'contactNo': contactNo,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
      role: map['role'],
      contactNo: map['contactNo'],
    );
  }
}