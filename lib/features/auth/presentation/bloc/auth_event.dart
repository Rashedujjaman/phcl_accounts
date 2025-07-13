part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
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
  final String email;
  final String password;
  final String name;
  final String contactNo;
  final String role;

  const SignUpEvent(this.email, this.password, this.name, this.contactNo, this.role);

  @override
  List<Object> get props => [email, password, name, contactNo];
}

class SignOutEvent extends AuthEvent {}