part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInEvent(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class SignUpEvent extends AuthEvent {
  final String firstName;
  final String lastName;
  final String contactNo;
  final String role;
  final String email;
  final String password;

  const SignUpEvent(
    this.firstName, 
    this.lastName, 
    this.contactNo, 
    this.role, 
    this.email, 
    this.password,
    );

  @override
  List<Object> get props => [email, password, firstName, lastName, contactNo, role];
}

class SignOutEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? contactNo;
  final File? profileImage;

  const UpdateProfileEvent({
    required this.userId,
    this.firstName,
    this.lastName,
    this.contactNo,
    this.profileImage,
  });

  @override
  List<Object> get props => [userId, firstName ?? '', lastName ?? '', contactNo ?? ''];
}