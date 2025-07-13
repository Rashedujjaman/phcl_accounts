import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phcl_accounts/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entry.dart';
// import 'package:phcl_accounts/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:phcl_accounts/core/errors/firebase_auth_failure.dart';


class TransactionRepositoryImpl implements TransactionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _firebaseAuth;
  final Uuid _uuid;

  TransactionRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseAuth firebaseAuth,
    Uuid? uuid,
  })  : _firestore = firestore,
        _storage = storage,
        _firebaseAuth = firebaseAuth,
        _uuid = uuid ?? Uuid();


  @override
  Future<void> addTransaction(TransactionEntity transaction, File? attachment) async {
    try {
      String? attachmentUrl;
      
      if (attachment != null) {
        final ref = _storage.ref().child('transaction_proofs/${_uuid.v4()}');
        await ref.putFile(attachment);
        attachmentUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('transactions').add({
        'type': transaction.type,
        'category': transaction.category,
        'clientId': transaction.clientId,
        'date': transaction.date,
        'amount': transaction.amount,
        'contactNo': transaction.contactNo,
        'description': transaction.description,
        'attachmentUrl': attachmentUrl,
        'createdBy': _firebaseAuth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (_) {
      throw const FirebaseAuthFailure();
    }
  }
  
  @override
  Future<List<TransactionEntity>> getTransactions() async {
    try {
      final snapshot = await _firestore.collection('transactions').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionEntity(
          id: doc.id,
          type: data['type'],
          category: data['category'],
          clientId: data['clientId'],
          date: (data['date'] as Timestamp).toDate(),
          amount: data['amount'],
          contactNo: data['contactNo'],
          description: data['description'],
          attachmentUrl: data['attachmentUrl'],
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (_) {
      throw const FirebaseAuthFailure();
    }
  }
}