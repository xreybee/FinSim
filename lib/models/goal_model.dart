import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String userId;
  final String name;
  final double targetPrice;
  final double currentSavings;
  final DateTime deadline;

  GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetPrice,
    required this.currentSavings,
    required this.deadline,
  });

  double get progress {
    if (targetPrice <= 0) return 1.0;
    final val = currentSavings / targetPrice;
    return val > 1.0 ? 1.0 : val;
  }

  double get percent {
    return progress * 100;
  }

  bool get isCompleted => currentSavings >= targetPrice;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'targetPrice': targetPrice,
      'currentSavings': currentSavings,
      'deadline': Timestamp.fromDate(deadline),
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDeadline;
    final dl = map['deadline'];
    if (dl is Timestamp) {
      parsedDeadline = dl.toDate();
    } else if (dl is String) {
      parsedDeadline = DateTime.tryParse(dl) ?? DateTime.now();
    } else {
      parsedDeadline = DateTime.now();
    }

    return GoalModel(
      id: docId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      targetPrice: (map['targetPrice'] as num?)?.toDouble() ?? 0.0,
      currentSavings: (map['currentSavings'] as num?)?.toDouble() ?? 0.0,
      deadline: parsedDeadline,
    );
  }
}
