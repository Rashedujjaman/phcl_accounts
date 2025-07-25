import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phcl_accounts/core/errors/firebase_auth_failure.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/get_current_user.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/sign_in.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/sign_up.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/sign_out.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/update_user_profile.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;
  final UpdateUserProfile updateUserProfile;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthBloc({
    required this.signIn, 
    required this.signUp, 
    required this.signOut,
    required this.getCurrentUser,
    required this.updateUserProfile,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInEvent>(_onSignInEvent);
    on<SignUpEvent>(_onSignUpEvent);
    on<SignOutEvent>(_onSignOutEvent);
    on<UpdateProfileEvent>(_onUpdateProfileEvent);
  }

  // Helper method to extract clean error messages
  String _extractErrorMessage(dynamic error) {
    if (error is FirebaseAuthFailure) {
      return error.message;
    }
    // For other exceptions, try to extract meaningful message
    String errorString = error.toString();
    if (errorString.contains('FirebaseAuthFailure(') && errorString.contains(')')) {
      // Extract message from "FirebaseAuthFailure(message)" format
      int startIndex = errorString.indexOf('(') + 1;
      int endIndex = errorString.lastIndexOf(')');
      if (startIndex > 0 && endIndex > startIndex) {
        return errorString.substring(startIndex, endIndex);
      }
    }
    return errorString;
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final userEntity = await getCurrentUser.call();
        emit(AuthAuthenticated(userEntity));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onSignInEvent(
    SignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await signIn.call(event.email, event.password);
      final userEntity = await getCurrentUser.call();
      emit(AuthAuthenticated(userEntity));
    } catch (e) {
      emit(AuthSignInError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onSignUpEvent(
    SignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    emit(AuthLoading());
    try {
      await signUp.call(
        event.firstName,
        event.lastName,
        event.contactNo,
        event.role,
        event.email,
        event.password,
      );
      emit(AuthSignUpSuccess());
      emit(currentState);
    } catch (e) {
      emit(AuthSignUpError(_extractErrorMessage(e)));
      emit(currentState);
    }
  }

  Future<void> _onSignOutEvent(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await signOut.call();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthSignOutError(_extractErrorMessage(e)));
    }
  }

  Future<void> _onUpdateProfileEvent(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    emit(ProfileUpdateLoading());
    try {
      final updatedUser = await updateUserProfile.call(
        userId: event.userId,
        firstName: event.firstName,
        lastName: event.lastName,
        contactNo: event.contactNo,
        profileImage: event.profileImage,
      );
      emit(ProfileUpdateSuccess(updatedUser));
      emit(AuthAuthenticated(updatedUser));
    } catch (e) {
      emit(ProfileUpdateError(_extractErrorMessage(e)));
      emit(currentState);
    }
  }
}
