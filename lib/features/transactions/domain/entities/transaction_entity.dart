import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionEntity {
  final String? id;
  final String type;
  final String category;
  final DateTime date;
  final double amount;
  final String? clientId;
  final String? contactNo;
  final String? note;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final bool? isDeleted;
  final String? deletedBy;
  final DateTime? updatedAt;
  
  TransactionEntity({
    this.id,
    required this.type,
    required this.category,
    required this.date,
    required this.amount,
    this.clientId,
    this.contactNo,
    this.note,
    this.attachmentUrl,
    this.attachmentType,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.isDeleted = false,
    this.deletedBy,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'category': category,
      'date': date,
      'amount': amount,
      'clientId': clientId,
      'contactNo': contactNo,
      'note': note,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'isDeleted': isDeleted,
      'deletedBy': deletedBy,
      'updatedAt': updatedAt,
    };
  }

  factory TransactionEntity.fromMap(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'],
      type: json['type'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      amount: json['amount'].toDouble(),
      clientId: json['clientId'],
      contactNo: json['contactNo'],
      note: json['note'],
      attachmentUrl: json['attachmentUrl'],
      attachmentType: json['attachmentType'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: DateTime.parse(json['createdAt']),
      isDeleted: json['isDeleted'] ?? false,
      deletedBy: json['deletedBy'],
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  factory TransactionEntity.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionEntity(
      id: doc.id,
      type: data['type'] ?? '',
      category: data['category'] ?? '',
      date: (data['date'] != null && data['date'] is Timestamp) ? (data['date'] as Timestamp).toDate() : DateTime.now(),
      amount: (data['amount'] != null) ? data['amount'].toDouble() : 0.0,
      clientId: data['clientId'],
      contactNo: data['contactNo'],
      note: data['note'],
      attachmentUrl: data['attachmentUrl'],
      attachmentType: data['attachmentType'],
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] != null && data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedBy: data['updatedBy'],
      isDeleted: data['isDeleted'] ?? false,
      deletedBy: data['deletedBy'],
      updatedAt: (data['updatedAt'] != null && data['updatedAt'] is Timestamp) ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}