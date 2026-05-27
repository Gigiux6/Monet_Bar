class TransactionModel {
  final String id;
  final String userId;
  final int points;
  final String type; // 'add' or 'redeem'
  final String description;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'points': points,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      points: map['points'] ?? 0,
      type: map['type'] ?? 'add',
      description: map['description'] ?? '',
      date: _parseDate(map['date']),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is String) return DateTime.parse(date);
    if (date is DateTime) return date;
    try {
      // Handles Firestore Timestamp dynamically to keep models package-independent
      return (date as dynamic).toDate();
    } catch (_) {
      try {
        return DateTime.fromMillisecondsSinceEpoch((date as dynamic).millisecondsSinceEpoch);
      } catch (_) {
        return DateTime.now();
      }
    }
  }
}
