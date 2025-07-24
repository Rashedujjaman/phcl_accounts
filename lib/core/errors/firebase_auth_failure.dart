import 'package:equatable/equatable.dart';

class FirebaseAuthFailure extends Equatable {
  final String message;

  const FirebaseAuthFailure([this.message = 'An unknown Firebase authentication error occurred.']);

  factory FirebaseAuthFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const FirebaseAuthFailure('Email is not valid or badly formatted.');
      case 'invalid-credential':
        return const FirebaseAuthFailure('Invalid password');
      case 'user-disabled':
        return const FirebaseAuthFailure('This user has been disabled. Please contact support.');
      case 'user-not-found':
        return const FirebaseAuthFailure('No user found with this email.');
      case 'wrong-password':
        return const FirebaseAuthFailure('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return const FirebaseAuthFailure('An account already exists with this email.');
      case 'operation-not-allowed':
        return const FirebaseAuthFailure('Operation not allowed. Contact support.');
      case 'weak-password':
        return const FirebaseAuthFailure('Password is too weak. Choose a stronger password.');
      case 'too-many-requests':
        return const FirebaseAuthFailure('Too many requests. Try again later.');
      case 'network-request-failed':
        return const FirebaseAuthFailure('Network error. Check your internet connection.');
      case 'channel-error':
        return const FirebaseAuthFailure('Channel error. Please try again.');
      default:
        return const FirebaseAuthFailure();
    }
  }

  @override
  List<Object?> get props => [message];
}