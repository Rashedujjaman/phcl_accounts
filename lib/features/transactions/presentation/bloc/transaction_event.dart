part of 'transaction_bloc.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? type;

  const LoadTransactions({this.startDate, this.endDate, this.type});

  @override
  List<Object> get props => [startDate ?? '', endDate ?? '', type ?? ''];
}

class RestoreTransactionsState extends TransactionEvent {
  final TransactionLoaded state;

  const RestoreTransactionsState(this.state);

  @override
  List<Object> get props => [state];
}

class AddTransaction extends TransactionEvent {
  final TransactionEntity transaction;
  final DateTime? startDate;
  final DateTime? endDate;

  const AddTransaction({
    required this.transaction,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object> get props => [transaction, startDate ?? '', endDate ?? ''];
}

class LoadCategories extends TransactionEvent {
  final String type;

  const LoadCategories(this.type);

  @override
  List<Object> get props => [type];
}

class UpdateTransaction extends TransactionEvent {
  final TransactionEntity transaction;
  final DateTime? startDate;
  final DateTime? endDate;

  const UpdateTransaction(this.transaction, this.startDate, this.endDate);

  @override
  List<Object> get props => [transaction];
}

class DeleteTransaction extends TransactionEvent {
  final String id;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? type;

  const DeleteTransaction(this.id, this.startDate, this.endDate, this.type);

  @override
  List<Object> get props => [id];
}

class UploadAttachment extends TransactionEvent {
  final String transactionType;
  final XFile file;

  const UploadAttachment(this.transactionType, this.file);

  @override
  List<Object> get props => [transactionType, file];
}

class AttachmentUploaded extends TransactionEvent {
  final String downloadUrl;

  const AttachmentUploaded(this.downloadUrl);

  @override
  List<Object> get props => [downloadUrl];
}