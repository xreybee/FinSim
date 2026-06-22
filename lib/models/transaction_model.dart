import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String category; // Makanan, Transportasi, Gaya Hidup, Hiburan, Dana Darurat
  final String note;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;
    final dt = map['date'];
    if (dt is Timestamp) {
      parsedDate = dt.toDate();
    } else if (dt is String) {
      parsedDate = DateTime.tryParse(dt) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      id: docId,
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Lainnya',
      note: map['note'] ?? '',
      date: parsedDate,
    );
  }
}
