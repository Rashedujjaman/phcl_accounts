import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';
import 'package:phcl_accounts/features/transactions/domain/repositories/transaction_repository.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _repository;

  TransactionBloc(this._repository) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<LoadCategories>(_onLoadCategories);
    on<UploadAttachment>(_onUploadAttachment);
    on<AttachmentUploaded>(_onAttachmentUploaded);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await _repository.getTransactions(
        startDate: event.startDate,
        endDate: event.endDate,
        type: event.type,
      );
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.addTransaction(event.transaction);
      emit(TransactionSuccess('Transaction added successfully'));
      add(LoadTransactions(
        startDate: event.startDate,
        endDate: event.endDate,
        type: event.transaction.type,
      ));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<TransactionState> emit,
  ) async {
    emit(CategoryLoading());
    try {
      final categories = await _repository.getCategories(type: event.type);
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.updateTransaction(event.transaction);
      emit(TransactionSuccess('Transaction updated successfully'));
      add(LoadTransactions(
        startDate: event.startDate,
        endDate: event.endDate,
        type: event.transaction.type,
      ));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.deleteTransaction(event.id);
      emit(TransactionSuccess('Transaction deleted successfully'));
      add(LoadTransactions(
        startDate: event.startDate,
        endDate: event.endDate,
        type: event.type,
      ));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onUploadAttachment(
    UploadAttachment event,
    Emitter<TransactionState> emit,
  ) async {
    emit(AttachmentUploading(0));
    
    try {
      final file = File(event.file.path);
      final type = event.transactionType;
      
      // Get the download URL
      final result = await _repository.uploadAttachment(file, type);
      
      emit(AttachmentUploadSuccess(result['url']!));
      add(AttachmentUploaded(result['url']!));
    } catch (e) {
      emit(AttachmentUploadFailure(e.toString()));
    }
  }

  Future<void> _onAttachmentUploaded(
    AttachmentUploaded event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionSuccess('Attachment uploaded successfully: ${event.downloadUrl}'));
  }
}