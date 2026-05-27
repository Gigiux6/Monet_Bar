// Mock data seeding module for Monet Bar Fidelity & Info App.
// Provides high-quality initial data for `menu_items` and `rewards`.

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isAvailable;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.isAvailable = true,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map, String docId) {
    return MenuItem(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }
}

class RewardCatalogItem {
  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final String imageUrl;
  final bool isAvailable;

  const RewardCatalogItem({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.imageUrl,
    this.isAvailable = true,
  });

  factory RewardCatalogItem.fromMap(Map<String, dynamic> map, String docId) {
    return RewardCatalogItem(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      pointsRequired: map['pointsRequired'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'pointsRequired': pointsRequired,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }
}

class MockDataSeed {
  /// Raw list of high-quality, high-end menu items matching categories:
  /// Caffetteria, Pasticceria, Cocktail, Snack.
  static const List<Map<String, dynamic>> menuItemsRaw = [
    // Caffetteria
    {
      'id': 'item_espresso',
      'name': 'Espresso Monet',
      'description': 'Espresso della nostra miscela speciale, 100% Arabica da coltivazioni sostenibili con note di cioccolato fondente e agrumi.',
      'price': 1.50,
      'category': 'Caffetteria',
      'imageUrl': 'assets/images/menu/espresso.png',
      'isAvailable': true,
    },
    {
      'id': 'item_cappuccino',
      'name': 'Cappuccino Velluto',
      'description': 'Vellutato cappuccino preparato con latte intero fresco biologico e il nostro blend espresso premium.',
      'price': 2.20,
      'category': 'Caffetteria',
      'imageUrl': 'assets/images/menu/cappuccino.png',
      'isAvailable': true,
    },
    {
      'id': 'item_croissant',
      'name': 'Croissant Artigianale al Burro',
      'description': 'Sfoglia artigianale al burro d\'Isigny, fragrante e dorata, disponibile vuota o farcita al momento con crema o confettura.',
      'price': 1.80,
      'category': 'Caffetteria',
      'imageUrl': 'assets/images/menu/croissant.png',
      'isAvailable': true,
    },
    {
      'id': 'item_cake_slice',
      'name': 'Torta del Giorno (Fetta)',
      'description': 'Una soffice fetta della nostra torta artigianale del giorno, realizzata con ingredienti freschi e stagionali.',
      'price': 4.50,
      'category': 'Caffetteria',
      'imageUrl': 'assets/images/menu/cake_slice.png',
      'isAvailable': true,
    },

    // Pasticceria
    {
      'id': 'item_monoporzione',
      'name': 'Monoporzione Monet',
      'description': 'Elegante dessert monoporzione: mousse al cioccolato bianco, inserto al lampone e croccante sablé al pistacchio.',
      'price': 5.50,
      'category': 'Pasticceria',
      'imageUrl': 'assets/images/menu/monoporzione.png',
      'isAvailable': true,
    },
    {
      'id': 'item_macarons',
      'name': 'Tris di Macarons',
      'description': 'Selezione di tre macarons assortiti: caramello salato, petali di rosa biologica e vaniglia Bourbon.',
      'price': 4.80,
      'category': 'Pasticceria',
      'imageUrl': 'assets/images/menu/macarons.png',
      'isAvailable': true,
    },
    {
      'id': 'item_muffin',
      'name': 'Muffin ai Mirtilli Selvatici',
      'description': 'Soffice muffin arricchito con mirtilli selvatici e rifinito con un leggero crumble croccante alle mandorle.',
      'price': 2.80,
      'category': 'Pasticceria',
      'imageUrl': 'assets/images/menu/muffin.png',
      'isAvailable': true,
    },

    // Cocktail
    {
      'id': 'item_spritz',
      'name': 'Monet Spritz',
      'description': 'L\'aperitivo veneziano rivisitato: Prosecco DOCG, Aperol, spruzzata di seltz ed una fetta d\'arancia fresca bio.',
      'price': 7.00,
      'category': 'Cocktail',
      'imageUrl': 'assets/images/menu/spritz.png',
      'isAvailable': true,
    },
    {
      'id': 'item_mojito',
      'name': 'Mojito Botanico',
      'description': 'Fresco e rigenerante: Rum bianco premium, menta piperita dal nostro orto, zucchero grezzo di canna e lime pressato.',
      'price': 9.00,
      'category': 'Cocktail',
      'imageUrl': 'assets/images/menu/mojito.png',
      'isAvailable': true,
    },
    {
      'id': 'item_negroni',
      'name': 'Negroni del Fondatore',
      'description': 'Intenso e bilanciato: Bitter Campari, Vermouth rosso riserva piemontese, London Dry Gin e zeste di arancia.',
      'price': 10.00,
      'category': 'Cocktail',
      'imageUrl': 'assets/images/menu/negroni.png',
      'isAvailable': true,
    },

    // Snack
    {
      'id': 'item_toast',
      'name': 'Toast Gourmet',
      'description': 'Pane artigianale in cassetta, prosciutto cotto alta qualità ramato, formaggio fuso svizzero Gruyère e burro salato alle erbe.',
      'price': 4.50,
      'category': 'Snack',
      'imageUrl': 'assets/images/menu/toast.png',
      'isAvailable': true,
    },
    {
      'id': 'item_sandwich',
      'name': 'Club Sandwich Monet',
      'description': 'Sandwich a strati con petto di pollo cotto a bassa temperatura, maionese artigianale al basilico, pomodorini confit e rucola fresca.',
      'price': 6.50,
      'category': 'Snack',
      'imageUrl': 'assets/images/menu/sandwich.png',
      'isAvailable': true,
    },
    {
      'id': 'item_chips',
      'name': 'Patatine Artigianali Rustiche',
      'description': 'Patate novelle tagliate a mano e cotte a bassa temperatura, servite con sale rosa dell\'Himalaya e pepe nero.',
      'price': 3.50,
      'category': 'Snack',
      'imageUrl': 'assets/images/menu/chips.png',
      'isAvailable': true,
    },
  ];

  /// Raw list of high-quality rewards catalog items.
  static const List<Map<String, dynamic>> rewardsRaw = [
    {
      'id': 'reward_caffe',
      'title': 'Caffè in Omaggio',
      'description': 'Gusta un espresso o un caffè macchiato preparato con la nostra miscela pregiata Monet.',
      'pointsRequired': 50,
      'imageUrl': 'assets/images/rewards/caffe.png',
      'isAvailable': true,
    },
    {
      'id': 'reward_colazione',
      'title': 'Brioche & Cappuccino',
      'description': 'La classica colazione all\'italiana: un cappuccino vellutato abbinato a un croissant artigianale a scelta.',
      'pointsRequired': 100,
      'imageUrl': 'assets/images/rewards/colazione.png',
      'isAvailable': true,
    },
    {
      'id': 'reward_monoporzione',
      'title': 'Monoporzione a Scelta',
      'description': 'Regalati una squisita monoporzione dalla nostra vetrina pasticceria d\'autore.',
      'pointsRequired': 200,
      'imageUrl': 'assets/images/rewards/monoporzione.png',
      'isAvailable': true,
    },
    {
      'id': 'reward_aperitivo',
      'title': 'Aperitivo Monet per Due',
      'description': 'Due spritz o calici di vino a scelta accompagnati da una selezione speciale di stuzzichini caldi e freddi.',
      'pointsRequired': 350,
      'imageUrl': 'assets/images/rewards/aperitivo.png',
      'isAvailable': true,
    },
    {
      'id': 'reward_tazza',
      'title': 'Tazza Personalizzata Monet',
      'description': 'Porta a casa un pezzo della nostra essenza: tazza da collezione in ceramica decorata artigianalmente.',
      'pointsRequired': 500,
      'imageUrl': 'assets/images/rewards/tazza.png',
      'isAvailable': true,
    },
  ];

  /// Strongly-typed list of menu items
  static List<MenuItem> get menuItems => menuItemsRaw
      .map((item) => MenuItem.fromMap(item, item['id'] as String))
      .toList();

  /// Strongly-typed list of rewards catalog items
  static List<RewardCatalogItem> get rewards => rewardsRaw
      .map((reward) => RewardCatalogItem.fromMap(reward, reward['id'] as String))
      .toList();

  /// Generic seed function that can be used with a Mock Firestore service or real Firestore database.
  /// Example usage:
  /// ```dart
  /// await MockDataSeed.seedDatabase(
  ///   saveMenuItem: (id, data) => firestore.collection('menu_items').doc(id).set(data),
  ///   saveReward: (id, data) => firestore.collection('rewards').doc(id).set(data),
  /// );
  /// ```
  static Future<void> seedDatabase({
    required Future<void> Function(String id, Map<String, dynamic> data) saveMenuItem,
    required Future<void> Function(String id, Map<String, dynamic> data) saveReward,
  }) async {
    for (final item in menuItemsRaw) {
      final data = Map<String, dynamic>.from(item)..remove('id');
      await saveMenuItem(item['id'] as String, data);
    }
    for (final reward in rewardsRaw) {
      final data = Map<String, dynamic>.from(reward)..remove('id');
      await saveReward(reward['id'] as String, data);
    }
  }
}
