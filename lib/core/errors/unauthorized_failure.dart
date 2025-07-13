import 'package:equatable/equatable.dart';

class UnauthorizedFailure extends Equatable {
  final String message;
  final int? statusCode;

  const UnauthorizedFailure({
    this.message = 'Unauthorized access',
    this.statusCode = 401,
  });

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => 'UnauthorizedFailure: $message (${statusCode ?? 'no status'})';
}