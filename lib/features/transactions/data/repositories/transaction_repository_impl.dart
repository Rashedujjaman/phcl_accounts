import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:phcl_accounts/core/errors/firebase_failure.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';
import 'package:phcl_accounts/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  TransactionRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _storage = storage,
        _auth = auth;

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw const FirebaseFailure('unauthenticated');

      await _firestore.collection('transactions').add({
        'type': transaction.type,
        'category': transaction.category,
        'date': transaction.date,
        'amount': transaction.amount,
        'clientId': transaction.clientId,
        'contactNo': transaction.contactNo,
        'note': transaction.note,
        'attachmentUrl': transaction.attachmentUrl,
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'updatedBy': '',
        'deletedBy': '',
      });
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      Query query = _firestore.collection('transactions')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => TransactionEntity.fromDocumentSnapshot(doc)
      ).toList();
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    try {
      if (transaction.id == null) throw const FirebaseFailure('Transaction ID is required');

      await _firestore.collection('transactions').doc(transaction.id).update({
        'type': transaction.type,
        'category': transaction.category,
        'date': transaction.date,
        'amount': transaction.amount,
        'clientId': transaction.clientId,
        'contactNo': transaction.contactNo,
        'note': transaction.note,
        'attachmentUrl': transaction.attachmentUrl,
        'updatedBy': _auth.currentUser?.uid,
        'dateUpdated': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      if (id.isEmpty) throw const FirebaseFailure('Transaction ID is required');

      await _firestore.collection('transactions').doc(id).update({
        'isDeleted': true,
        'deletedBy': _auth.currentUser?.uid,
        'dateDeleted': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

  @override
  Future<List<String>> getCategories({required String type}) async {
    try {
      final snapshot = type == 'expense'
          ? await _firestore.collection('expenseCategories').get()
          : await _firestore.collection('incomeCategories').get();
      
      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

  @override
  Future<String> uploadAttachment(File file) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw const FirebaseFailure('Unauthenticated');

      final ref = _storage.ref().child('attachments/$userId/${file.path.split('/').last}');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

  @override
  Future<void> deleteAttachment(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw FirebaseFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseFailure(e.toString());
    }
  }

}