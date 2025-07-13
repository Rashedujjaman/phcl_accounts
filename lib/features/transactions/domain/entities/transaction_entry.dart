class TransactionEntity {
  final String? id;
  final String type;
  final String category;
  final String clientId;
  final DateTime date;
  final double amount;
  final String? contactNo;
  final String? description;
  final String? attachmentUrl;
  
  TransactionEntity({
    this.id,
    required this.type,
    required this.category,
    required this.clientId,
    required this.date,
    required this.amount,
    this.contactNo,
    this.description,
    this.attachmentUrl,
  });
}