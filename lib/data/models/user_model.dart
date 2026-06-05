class UserModel {
  final String id;
  final String name;
  final String email;
  final int pointsBalance;
  final String role;
  bool isAutoLinked;
  final Map<String, dynamic> importantDates;
  final List<String> recurringDatesMmDd;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.pointsBalance,
    this.role = 'client',
    this.isAutoLinked = false,
    this.importantDates = const {},
    this.recurringDatesMmDd = const [],
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? pointsBalance,
    String? role,
    bool? isAutoLinked,
    Map<String, dynamic>? importantDates,
    List<String>? recurringDatesMmDd,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      role: role ?? this.role,
      isAutoLinked: isAutoLinked ?? this.isAutoLinked,
      importantDates: importantDates ?? this.importantDates,
      recurringDatesMmDd: recurringDatesMmDd ?? this.recurringDatesMmDd,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'points': pointsBalance,
      'role': role,
      'importantDates': importantDates,
      'recurringDatesMmDd': recurringDatesMmDd,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      pointsBalance: map['points'] ?? map['pointsBalance'] ?? 0,
      role: map['role'] ?? 'client',
      importantDates: Map<String, dynamic>.from(map['importantDates'] ?? {}),
      recurringDatesMmDd: List<String>.from(map['recurringDatesMmDd'] ?? []),
    );
  }
}
