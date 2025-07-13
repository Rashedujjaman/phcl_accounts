import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/sign_in.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/sign_up.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthBloc({required this.signIn, required this.signUp}) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInEvent>(_onSignInEvent);
    on<SignUpEvent>(_onSignUpEvent);
    on<SignOutEvent>(_onSignOutEvent);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event, 
    Emitter<AuthState> emit
  ) async {
    emit(AuthLoading());
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInEvent(SignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await signIn.call(event.email, event.password);
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUpEvent(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await signUp.call(
        event.email, 
        event.password,
        event.name,
        event.contactNo,
        event.role
      );
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOutEvent(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthInitial());
  }
}