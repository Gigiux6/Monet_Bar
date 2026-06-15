import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String rewardId;
  final String rewardTitle;
  final int pointsSpent;
  final String userId;
  final DateTime claimDate;
  final DateTime expiryDate;
  final String status; // 'active' or 'used'

  Coupon({
    required this.id,
    required this.rewardId,
    required this.rewardTitle,
    required this.pointsSpent,
    required this.userId,
    required this.claimDate,
    required this.expiryDate,
    required this.status,
  });

  Coupon copyWith({
    String? id,
    String? rewardId,
    String? rewardTitle,
    int? pointsSpent,
    String? userId,
    DateTime? claimDate,
    DateTime? expiryDate,
    String? status,
  }) {
    return Coupon(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      rewardTitle: rewardTitle ?? this.rewardTitle,
      pointsSpent: pointsSpent ?? this.pointsSpent,
      userId: userId ?? this.userId,
      claimDate: claimDate ?? this.claimDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id': id, RIMOSSO: Evitiamo di duplicare l'ID dentro il payload Firestore
      'rewardId': rewardId,
      'rewardTitle': rewardTitle,
      'pointsSpent': pointsSpent,
      'userId': userId,
      'claimDate': Timestamp.fromDate(claimDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status,
    };
  }

  factory Coupon.fromMap(Map<String, dynamic> map, String docId) {
    return Coupon(
      id: docId,
      rewardId: map['rewardId'] ?? '',
      rewardTitle: map['rewardTitle'] ?? '',
      pointsSpent: map['pointsSpent'] ?? 0,
      userId: map['userId'] ?? '',
      claimDate: _parseDate(map['claimDate']),
      expiryDate: _parseDate(map['expiryDate']),
      status: map['status'] ?? 'active',
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    
    // Fallback sicuro
    try {
      return DateTime.fromMillisecondsSinceEpoch((date as dynamic).millisecondsSinceEpoch);
    } catch (_) {
      return DateTime.now();
    }
  }
}
