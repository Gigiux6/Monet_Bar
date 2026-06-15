class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String iconName;
  final String terms;
  final String? imageUrl;
  final bool isSpecial;
  final int validityDays;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.iconName,
    required this.terms,
    this.imageUrl,
    this.isSpecial = false,
    this.validityDays = 0,
  });

  // Metodo essenziale per la modifica immutabile (utile per il pannello Admin)
  Reward copyWith({
    String? id,
    String? title,
    String? description,
    int? pointsCost,
    String? iconName,
    String? terms,
    String? imageUrl,
    bool? isSpecial,
    int? validityDays,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      iconName: iconName ?? this.iconName,
      terms: terms ?? this.terms,
      imageUrl: imageUrl ?? this.imageUrl,
      isSpecial: isSpecial ?? this.isSpecial,
      validityDays: validityDays ?? this.validityDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id': id, -> RIMOSSO: Evitiamo di duplicare l'ID dentro il payload Firestore
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'iconName': iconName,
      'terms': terms,
      'imageUrl': imageUrl,
      'isSpecial': isSpecial,
      'validityDays': validityDays,
    };
  }

  factory Reward.fromMap(Map<String, dynamic> map, String docId) {
    return Reward(
      id: docId, // L'ID proviene dal Documento, non dai campi interni
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      // Supporto per database vecchi che usavano 'pointsRequired'
      pointsCost: map['pointsCost'] ?? map['pointsRequired'] ?? 0,
      iconName: map['iconName'] ?? '',
      terms: map['terms'] ?? '',
      imageUrl: map['imageUrl'],
      isSpecial: map['isSpecial'] ?? false,
      validityDays: map['validityDays'] ?? 0,
    );
  }
}
