part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthSignUpSuccess extends AuthState {}

class AuthSignUpError extends AuthState {
  final String message;

  const AuthSignUpError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthSignInError extends AuthState {
  final String message;

  const AuthSignInError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthSignOutSuccess extends AuthState {}

class AuthSignOutError extends AuthState {
  final String message;

  const AuthSignOutError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class ProfileUpdateLoading extends AuthState {}

class ProfileUpdateSuccess extends AuthState {
  final UserEntity updatedUser;

  const ProfileUpdateSuccess(this.updatedUser);

  @override
  List<Object> get props => [updatedUser];
}

class ProfileUpdateError extends AuthState {
  final String message;

  const ProfileUpdateError(this.message);

  @override
  List<Object> get props => [message];
}