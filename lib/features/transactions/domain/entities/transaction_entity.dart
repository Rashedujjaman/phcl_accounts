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
  final String? updatedBy;
  final String? deletedBy;
  final DateTime? dateUpdated;
  
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
    this.updatedBy,
    this.deletedBy,
    this.dateUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'amount': amount,
      'clientId': clientId,
      'contactNo': contactNo,
      'note': note,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deletedBy': deletedBy,
      'dateUpdated': dateUpdated?.toIso8601String(),
    };
  }

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
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
      deletedBy: json['deletedBy'],
      dateUpdated: json['dateUpdated'] != null ? DateTime.parse(json['dateUpdated']) : null,
    );
  }

  factory TransactionEntity.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionEntity(
      id: doc.id,
      type: data['type'],
      category: data['category'],
      date: (data['date'] as Timestamp).toDate(),
      amount: data['amount'].toDouble(),
      clientId: data['clientId'],
      contactNo: data['contactNo'],
      note: data['note'],
      attachmentUrl: data['attachmentUrl'],
      attachmentType: data['attachmentType'],
      createdBy: data['createdBy'],
      updatedBy: data['updatedBy'],
      deletedBy: data['deletedBy'],
      dateUpdated: data['dateUpdated'] != null ? (data['dateUpdated'] as Timestamp).toDate() : null,
    );
  }
}