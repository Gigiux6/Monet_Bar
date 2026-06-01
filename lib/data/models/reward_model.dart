class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String iconName;
  final String terms;
  final String? imageUrl;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.iconName,
    required this.terms,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'iconName': iconName,
      'terms': terms,
      'imageUrl': imageUrl,
    };
  }

  factory Reward.fromMap(Map<String, dynamic> map, String docId) {
    return Reward(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      pointsCost: map['pointsCost'] ?? map['pointsRequired'] ?? 0,
      iconName: map['iconName'] ?? '',
      terms: map['terms'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}
