part of 'transaction_bloc.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  final DateTime? currentStartDate;
  final DateTime? currentEndDate;
  final String? currentType;

  const TransactionLoaded(
    this.transactions, {
    this.currentStartDate,
    this.currentEndDate,
    this.currentType,
  });

  @override
  List<Object> get props => [transactions, currentStartDate ?? '', currentEndDate ?? '', currentType ?? ''];
}

class CategoryLoading extends TransactionState {}

class CategoryLoaded extends TransactionState {
  final List<String> categories;

  const CategoryLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

class TransactionSuccess extends TransactionState {
  final String message;

  const TransactionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object> get props => [message];
}

class AttachmentUploading extends TransactionState {
  final double progress;

  const AttachmentUploading(this.progress);

  @override
  List<Object> get props => [progress];
}

class AttachmentUploadSuccess extends TransactionState {
  final String downloadUrl;

  const AttachmentUploadSuccess(this.downloadUrl);

  @override
  List<Object> get props => [downloadUrl];
}

class AttachmentUploadFailure extends TransactionState {
  final String error;

  const AttachmentUploadFailure(this.error);

  @override
  List<Object> get props => [error];
}