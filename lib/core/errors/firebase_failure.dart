import 'package:equatable/equatable.dart';

class FirebaseFailure extends Equatable implements Exception {
  final String message;
  final String? code;

  const FirebaseFailure([this.message = 'An unknown Firebase error occurred.', this.code]);

  factory FirebaseFailure.fromCode(String code) {
    switch (code) {
      case 'permission-denied':
        return const FirebaseFailure('You do not have permission to perform this operation.', 'permission-denied');
      case 'unavailable':
        return const FirebaseFailure('The service is currently unavailable. Please try again later.', 'unavailable');
      case 'not-found':
        return const FirebaseFailure('Requested resource was not found.', 'not-found');
      case 'already-exists':
        return const FirebaseFailure('Resource already exists.', 'already-exists');
      case 'cancelled':
        return const FirebaseFailure('The operation was cancelled.', 'cancelled');
      case 'deadline-exceeded':
        return const FirebaseFailure('The operation took too long to complete.', 'deadline-exceeded');
      case 'resource-exhausted':
        return const FirebaseFailure('Resource exhausted. Try again later.', 'resource-exhausted');
      case 'internal':
        return const FirebaseFailure('Internal server error occurred.', 'internal');
      case 'unauthenticated':
        return const FirebaseFailure('You are not authenticated. Please log in.', 'unauthenticated');
      case 'failed-precondition':
        return const FirebaseFailure('Missing composite index. Check Firebase console to create it.');
      default:
        return FirebaseFailure('An unknown Firebase error occurred. Code: $code', code);
    }
  }

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'FirebaseFailure(code: $code, message: $message)';
}