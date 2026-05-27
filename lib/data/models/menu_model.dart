enum MenuCategory {
  caffetteria,
  pasticceria,
  cocktail,
  snack;

  String get displayName {
    switch (this) {
      case MenuCategory.caffetteria:
        return 'Caffetteria';
      case MenuCategory.pasticceria:
        return 'Pasticceria';
      case MenuCategory.cocktail:
        return 'Cocktails';
      case MenuCategory.snack:
        return 'Snack & Food';
    }
  }
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final MenuCategory category;
  final List<String> ingredients;
  final bool isSignature;
  final String? iconName; // Helper to display representative icons

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.ingredients,
    this.isSignature = false,
    this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category.name,
      'ingredients': ingredients,
      'isSignature': isSignature,
      'iconName': iconName,
      'isAvailable': true,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map, String docId) {
    return MenuItem(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: MenuCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => MenuCategory.caffetteria,
      ),
      ingredients: List<String>.from(map['ingredients'] ?? []),
      isSignature: map['isSignature'] ?? false,
      iconName: map['iconName'] ?? map['imageUrl'],
    );
  }
}
