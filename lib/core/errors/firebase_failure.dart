import 'package:equatable/equatable.dart';

// ============================================================================
// FIREBASE FAILURE CLASS
// ============================================================================
// This file defines a custom exception class for handling Firebase-related
// errors throughout the application. It provides user-friendly error messages
// for common Firebase error codes and implements Equatable for value comparison.
//
// Used by: Repository layer, BLoC layer for error state management
// ============================================================================

/// Custom exception class for Firebase-related errors
///
/// Provides standardized error handling for Firebase operations including
/// Firestore, Authentication, and Storage. Converts Firebase error codes
/// into user-friendly messages that can be displayed in the UI.
///
/// **Features:**
/// - Implements [Exception] for throwable errors
/// - Extends [Equatable] for value-based equality comparisons
/// - Factory constructor for automatic error code mapping
/// - User-friendly error messages for all common Firebase error codes
///
/// **Common Error Codes:**
/// - `permission-denied`: User lacks required permissions
/// - `unavailable`: Service temporarily unavailable
/// - `not-found`: Requested resource doesn't exist
/// - `already-exists`: Resource duplication attempt
/// - `unauthenticated`: User not logged in
/// - `deadline-exceeded`: Operation timeout
/// - `failed-precondition`: Missing database index
///
/// **Usage:**
/// ```dart
/// // Manual creation
/// throw FirebaseFailure('Custom error message', 'custom-code');
///
/// // From Firebase error code
/// try {
///   await FirebaseFirestore.instance.collection('transactions').get();
/// } catch (e) {
///   if (e is FirebaseException) {
///     throw FirebaseFailure.fromCode(e.code);
///   }
/// }
///
/// // In BLoC state
/// return state.copyWith(
///   status: Status.error,
///   failure: FirebaseFailure.fromCode(error.code),
/// );
/// ```
///
/// **Example Error Flow:**
/// ```
/// Firebase Operation → Error → FirebaseFailure.fromCode()
///                                      ↓
///                           User-Friendly Message
///                                      ↓
///                              BLoC Error State
///                                      ↓
///                            UI Error Display
/// ```
class FirebaseFailure extends Equatable implements Exception {
  /// User-friendly error message describing what went wrong
  ///
  /// This message is safe to display directly to end users.
  /// Defaults to generic message if not specified.
  final String message;

  /// Firebase error code (e.g., 'permission-denied', 'not-found')
  ///
  /// Used for programmatic error handling and debugging.
  /// Optional - can be null for custom errors.
  final String? code;

  /// Creates a new [FirebaseFailure] with optional message and code
  ///
  /// **Parameters:**
  /// - [message]: Human-readable error description (default: generic error)
  /// - [code]: Firebase error code for categorization (optional)
  ///
  /// **Example:**
  /// ```dart
  /// const error = FirebaseFailure(
  ///   'Unable to save transaction',
  ///   'permission-denied',
  /// );
  /// ```
  const FirebaseFailure([
    this.message = 'An unknown Firebase error occurred.',
    this.code,
  ]);

  /// Creates a [FirebaseFailure] from a Firebase error code
  ///
  /// Automatically maps Firebase error codes to user-friendly messages.
  /// This is the recommended way to create FirebaseFailure instances
  /// when catching Firebase exceptions.
  ///
  /// **Supported Error Codes:**
  ///
  /// | Code | User Message | Common Cause |
  /// |------|-------------|--------------|
  /// | `permission-denied` | No permission for operation | Missing Firestore rules |
  /// | `unavailable` | Service unavailable | Network/server issues |
  /// | `not-found` | Resource not found | Deleted/non-existent document |
  /// | `already-exists` | Resource already exists | Duplicate ID/constraint violation |
  /// | `cancelled` | Operation cancelled | User/system cancellation |
  /// | `deadline-exceeded` | Operation timeout | Slow network/large query |
  /// | `resource-exhausted` | Resource limit reached | Quota exceeded |
  /// | `internal` | Internal server error | Firebase backend issue |
  /// | `unauthenticated` | Not authenticated | User not logged in |
  /// | `failed-precondition` | Missing index | Composite index needed |
  ///
  /// **Parameters:**
  /// - [code]: Firebase error code string
  ///
  /// **Returns:**
  /// A [FirebaseFailure] instance with appropriate user-friendly message
  ///
  /// **Example:**
  /// ```dart
  /// try {
  ///   await transactionRef.delete();
  /// } on FirebaseException catch (e) {
  ///   final failure = FirebaseFailure.fromCode(e.code);
  ///   print(failure.message); // "You do not have permission..."
  /// }
  /// ```
  factory FirebaseFailure.fromCode(String code) {
    switch (code) {
      // Security & Permission Errors
      case 'permission-denied':
        return const FirebaseFailure(
          'You do not have permission to perform this operation.',
          'permission-denied',
        );
      case 'unauthenticated':
        return const FirebaseFailure(
          'You are not authenticated. Please log in.',
          'unauthenticated',
        );

      // Availability & Network Errors
      case 'unavailable':
        return const FirebaseFailure(
          'The service is currently unavailable. Please try again later.',
          'unavailable',
        );
      case 'deadline-exceeded':
        return const FirebaseFailure(
          'The operation took too long to complete.',
          'deadline-exceeded',
        );

      // Resource Errors
      case 'not-found':
        return const FirebaseFailure(
          'Requested resource was not found.',
          'not-found',
        );
      case 'already-exists':
        return const FirebaseFailure(
          'Resource already exists.',
          'already-exists',
        );
      case 'resource-exhausted':
        return const FirebaseFailure(
          'Resource exhausted. Try again later.',
          'resource-exhausted',
        );

      // Operation Errors
      case 'cancelled':
        return const FirebaseFailure(
          'The operation was cancelled.',
          'cancelled',
        );
      case 'failed-precondition':
        return const FirebaseFailure(
          'Missing composite index. Check Firebase console to create it.',
        );

      // Server Errors
      case 'internal':
        return const FirebaseFailure(
          'Internal server error occurred.',
          'internal',
        );

      // Unknown/Unmapped Errors
      default:
        return FirebaseFailure(
          'An unknown Firebase error occurred. Code: $code',
          code,
        );
    }
  }

  /// Properties used for equality comparison
  ///
  /// Compares both [message] and [code] for determining if two
  /// FirebaseFailure instances are equal.
  @override
  List<Object?> get props => [message, code];

  /// Returns a string representation of this failure
  ///
  /// Useful for debugging and logging purposes.
  ///
  /// **Format:**
  /// ```
  /// FirebaseFailure(code: <code>, message: <message>)
  /// ```
  ///
  /// **Example:**
  /// ```dart
  /// final error = FirebaseFailure.fromCode('permission-denied');
  /// print(error);
  /// // Output: FirebaseFailure(code: permission-denied, message: You do not have permission...)
  /// ```
  @override
  String toString() => 'FirebaseFailure(code: $code, message: $message)';
}
