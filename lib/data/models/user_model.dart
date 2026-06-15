import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final int points;
  final String role;
  final bool isAutoLinked;
  final Map<String, DateTime> importantDates;
  final List<String> recurringDatesMmDd;
  final bool isTemporary;
  final bool onboardingCompleted;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.points,
    this.role = 'client',
    this.isAutoLinked = false,
    this.importantDates = const {},
    this.recurringDatesMmDd = const [],
    this.isTemporary = false,
    this.onboardingCompleted = false,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? points,
    String? role,
    bool? isAutoLinked,
    Map<String, DateTime>? importantDates,
    List<String>? recurringDatesMmDd,
    bool? isTemporary,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      points: points ?? this.points,
      role: role ?? this.role,
      isAutoLinked: isAutoLinked ?? this.isAutoLinked,
      importantDates: importantDates ?? this.importantDates,
      recurringDatesMmDd: recurringDatesMmDd ?? this.recurringDatesMmDd,
      isTemporary: isTemporary ?? this.isTemporary,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    // Riconvertiamo DateTime in Timestamp prima di salvare su Firebase
    final Map<String, Timestamp> firebaseDates = {};
    importantDates.forEach((key, date) {
      firebaseDates[key] = Timestamp.fromDate(date);
    });

    return {
      'id': id,
      'name': name,
      'email': email,
      'points': points,
      'role': role,
      'importantDates': firebaseDates,
      'recurringDatesMmDd': recurringDatesMmDd,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Decodifichiamo i Timestamp di Firebase in DateTime puri di Dart
    final Map<String, DateTime> parsedDates = {};
    if (map['importantDates'] != null) {
      final Map<String, dynamic> rawDates = map['importantDates'] as Map<String, dynamic>;
      rawDates.forEach((key, value) {
        if (value is Timestamp) {
          parsedDates[key] = value.toDate();
        } else if (value is String) {
          // Fallback nel caso in cui le date fossero salvate come stringhe ISO
          parsedDates[key] = DateTime.parse(value);
        }
      });
    }

    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      points: map['points'] ?? map['pointsBalance'] ?? 0, // Manteniamo la retrocompatibilità in lettura
      role: map['role'] ?? 'client',
      importantDates: parsedDates,
      recurringDatesMmDd: List<String>.from(map['recurringDatesMmDd'] ?? []),
      isTemporary: map['isTemporary'] ?? false,
      onboardingCompleted: map['onboardingCompleted'] ?? map['importantDates']?['onboarding_completed'] ?? false,
    );
  }
}
