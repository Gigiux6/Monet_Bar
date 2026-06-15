import 'dart:async';
import '../models/user_model.dart';
import '../models/menu_model.dart';
import '../models/reward_model.dart';
import '../models/coupon_model.dart';
import '../models/transaction_model.dart';

/// A Mock Authentication Service simulating FirebaseAuth.
class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal() {
    // Check if user is already logged in or initialize
    _currentUser = UserModel(
      id: 'monet_customer_777',
      name: 'Claude Monet',
      email: 'claude.monet@bar.it',
      points: 120, // Start with some initial points to showcase progress bar
    );
    _userController.add(_currentUser);
  }

  UserModel? _currentUser;
  final StreamController<UserModel?> _userController = StreamController<UserModel?>.broadcast();

  UserModel? get currentUser => _currentUser;
  Stream<UserModel?> get userStateChanges => _userController.stream;

  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network latency
    _currentUser = UserModel(
      id: 'monet_customer_777',
      name: 'Claude Monet',
      email: email,
      points: 120,
    );
    _userController.add(_currentUser);
    // Sync points state with MockFirestoreService
    MockFirestoreService()._syncUserPoints(_currentUser!.points);
    return _currentUser;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = null;
    _userController.add(null);
  }

  void updateLocalUserPoints(int newPoints) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(points: newPoints);
      _userController.add(_currentUser);
    }
  }
}

/// A Mock Firestore Service simulating FirebaseFirestore.
class MockFirestoreService {
  static final MockFirestoreService _instance = MockFirestoreService._internal();
  factory MockFirestoreService() => _instance;
  MockFirestoreService._internal() {
    // Populate static data
    _initMenu();
    _initRewards();
    // Start user with one active and one used coupon to show variety
    _coupons = [
      Coupon(
        id: 'CPN-9843-USED',
        rewardId: 'rew_1',
        rewardTitle: "Espresso d'Autore",
        pointsSpent: 100,
        userId: 'monet_customer_777',
        claimDate: DateTime.now().subtract(const Duration(days: 5)),
        expiryDate: DateTime.now().subtract(const Duration(days: 2)),
        status: 'used',
      ),
      Coupon(
        id: 'CPN-1234-ACTV',
        rewardId: 'rew_2',
        rewardTitle: 'Croissant Artigianale',
        pointsSpent: 150,
        userId: 'monet_customer_777',
        claimDate: DateTime.now().subtract(const Duration(hours: 2)),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        status: 'active',
      ),
    ];
    _transactions = [
      TransactionModel(
        id: 'TXN-001',
        userId: 'monet_customer_777',
        points: 200,
        type: 'add',
        description: 'Benvenuto in Monet Bar',
        date: DateTime.now().subtract(const Duration(days: 6)),
      ),
      TransactionModel(
        id: 'TXN-002',
        userId: 'monet_customer_777',
        points: 100,
        type: 'redeem',
        description: "Riscatto Espresso d'Autore",
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      TransactionModel(
        id: 'TXN-003',
        userId: 'monet_customer_777',
        points: 170,
        type: 'add',
        description: 'Consumazione Tavolo',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: 'TXN-004',
        userId: 'monet_customer_777',
        points: 150,
        type: 'redeem',
        description: 'Riscatto Croissant Artigianale',
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
    _notifyAll();
  }

  // Collections (In-memory storage)
  List<MenuItem> _menuItems = [];
  List<Reward> _rewards = [];
  List<Coupon> _coupons = [];
  List<TransactionModel> _transactions = [];

  // Stream controllers to mimic snapshot streams
  final StreamController<List<Coupon>> _couponsController = StreamController<List<Coupon>>.broadcast();
  final StreamController<List<TransactionModel>> _transactionsController = StreamController<List<TransactionModel>>.broadcast();

  // Getters for static / current values
  List<MenuItem> get menuItems => _menuItems;
  List<Reward> get rewards => _rewards;

  // Streams
  Stream<List<Coupon>> get couponsStream => _couponsController.stream;
  Stream<List<TransactionModel>> get transactionsStream => _transactionsController.stream;

  void _syncUserPoints(int points) {
    // Keep local sync in case user logs in/out
    _notifyAll();
  }

  void _notifyAll() {
    _couponsController.add(List.unmodifiable(_coupons));
    _transactionsController.add(List.unmodifiable(_transactions));
  }

  /// Add points to a user. Used by Admin Panel.
  Future<bool> addPoints(String userId, int points, String description) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final currentUser = MockAuthService().currentUser;
    
    // Create transaction
    final newTx = TransactionModel(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      points: points,
      type: 'add',
      description: description,
      date: DateTime.now(),
    );
    _transactions.insert(0, newTx);

    // If it's the current user, update their points
    if (currentUser != null && currentUser.id == userId) {
      final updatedPoints = currentUser.points + points;
      MockAuthService().updateLocalUserPoints(updatedPoints);
    }
    _notifyAll();
    return true;
  }

  /// Redeem a reward. Deducts points and generates a coupon.
  Future<Map<String, dynamic>> redeemReward(Reward reward) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final currentUser = MockAuthService().currentUser;
    if (currentUser == null) {
      return {'success': false, 'message': 'Utente non autenticato'};
    }

    if (currentUser.points < reward.pointsCost) {
      return {'success': false, 'message': 'Punti insufficienti per riscattare questo premio'};
    }

    // Deduct points
    final newBalance = currentUser.points - reward.pointsCost;
    MockAuthService().updateLocalUserPoints(newBalance);

    // Create coupon
    final couponId = 'CPN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${reward.id.toUpperCase()}';
    final coupon = Coupon(
      id: couponId,
      rewardId: reward.id,
      rewardTitle: reward.title,
      pointsSpent: reward.pointsCost,
      userId: currentUser.id,
      claimDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      status: 'active',
    );
    _coupons.insert(0, coupon);

    // Add transaction history
    final newTx = TransactionModel(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUser.id,
      points: reward.pointsCost,
      type: 'redeem',
      description: 'Riscatto ${reward.title}',
      date: DateTime.now(),
    );
    _transactions.insert(0, newTx);

    _notifyAll();
    return {'success': true, 'coupon': coupon};
  }

  /// Validate a coupon. Updates coupon status to 'used'.
  Future<bool> validateCoupon(String couponId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    int index = _coupons.indexWhere((c) => c.id == couponId);
    if (index != -1) {
      _coupons[index] = _coupons[index].copyWith(status: 'used');
      _notifyAll();
      return true;
    }
    return false;
  }

  // Populate Mock Menu Data
  void _initMenu() {
    _menuItems = [
      MenuItem(
        id: 'm_1',
        name: 'Espresso Monet',
        description: 'Miscela arabica selezione speciale Monet, con note di cacao e nocciola.',
        price: 1.50,
        category: MenuCategory.caffetteria,
        ingredients: ['Caffè Arabica', 'Miscela Artigianale', 'Acqua filtrata'],
        isSignature: true,
        iconName: 'local_cafe',
      ),
      MenuItem(
        id: 'm_2',
        name: 'Cappuccino d\'Oro',
        description: 'Crema di latte vellutata, espresso biologico, spolverata di cacao e scaglie d\'oro edibili.',
        price: 2.80,
        category: MenuCategory.caffetteria,
        ingredients: ['Latte fresco bio', 'Espresso Monet', 'Cacao amaro', 'Scaglie d\'oro 23k'],
        isSignature: true,
        iconName: 'coffee',
      ),
      MenuItem(
        id: 'm_3',
        name: 'Caffè Shakerato Art',
        description: 'Doppio espresso shakerato con ghiaccio e sciroppo di vaniglia del Madagascar.',
        price: 3.50,
        category: MenuCategory.caffetteria,
        ingredients: ['Doppio Espresso', 'Sciroppo alla vaniglia', 'Ghiaccio tritato'],
        iconName: 'local_bar',
      ),
      MenuItem(
        id: 'm_4',
        name: 'Cornetto Monna Lisa',
        description: 'Sfoglia croccante al burro di Normandia con ricca crema pasticcera alla vaniglia Bourbon.',
        price: 1.80,
        category: MenuCategory.pasticceria,
        ingredients: ['Farina biologica', 'Burro francese', 'Crema pasticcera', 'Uova free-range'],
        isSignature: true,
        iconName: 'cake',
      ),
      MenuItem(
        id: 'm_5',
        name: 'Sacher Antigravity',
        description: 'Morbido pan di spagna al cioccolato fondente 72% con confettura di albicocche artigianale.',
        price: 4.50,
        category: MenuCategory.pasticceria,
        ingredients: ['Cioccolato fondente 72%', 'Confettura di albicocche', 'Farina', 'Uova'],
        iconName: 'bakery_dining',
      ),
      MenuItem(
        id: 'm_6',
        name: 'Torta Impressionista',
        description: 'Crostata moderna con crema di limone di Sorrento e frutti di bosco freschi disposti a mosaico.',
        price: 5.00,
        category: MenuCategory.pasticceria,
        ingredients: ['Pasta frolla', 'Crema di limone', 'Mirtilli', 'Lamponi', 'Fragoline selvatiche'],
        isSignature: true,
        iconName: 'cake',
      ),
      MenuItem(
        id: 'm_7',
        name: 'Claude\'s Spritz',
        description: 'Prosecco DOCG, liquore ai fiori di sambuco, soda, menta fresca e spicchio di lime.',
        price: 7.50,
        category: MenuCategory.cocktail,
        ingredients: ['Prosecco DOCG', 'Liquore sambuco (St. Germain)', 'Soda', 'Menta fresca', 'Lime'],
        isSignature: true,
        iconName: 'local_bar',
      ),
      MenuItem(
        id: 'm_8',
        name: 'Monet\'s Sunset',
        description: 'Gin premium, infuso ai frutti rossi, succo di limone fresco e tonica all\'ibisco.',
        price: 9.00,
        category: MenuCategory.cocktail,
        ingredients: ['Gin premium', 'Infuso frutti rossi', 'Succo di limone', 'Acqua tonica all\'ibisco'],
        iconName: 'liquor',
      ),
      MenuItem(
        id: 'm_9',
        name: 'Amber Negroni',
        description: 'Gin infuso allo zafferano, Vermouth bianco premium, Campari ed una buccia d\'arancia bruciata.',
        price: 10.00,
        category: MenuCategory.cocktail,
        ingredients: ['Gin allo zafferano', 'Vermouth bianco', 'Campari', 'Arancia essiccata', 'Polvere d\'oro alimentare'],
        isSignature: true,
        iconName: 'local_bar',
      ),
      MenuItem(
        id: 'm_10',
        name: 'Toast Gourmet',
        description: 'Pane artigianale a lievitazione naturale tostata, prosciutto cotto braciato e fontina valdostana DOP.',
        price: 6.00,
        category: MenuCategory.snack,
        ingredients: ['Pane a lievitazione naturale', 'Prosciutto cotto braciato', 'Fontina DOP', 'Burro salato'],
        iconName: 'breakfast_dining',
      ),
      MenuItem(
        id: 'm_11',
        name: 'Monet Pinsa',
        description: 'Pinsa romana ad alta idratazione con mortadella premium, stracciatella di bufala e granella di pistacchio.',
        price: 9.50,
        category: MenuCategory.snack,
        ingredients: ['Farina di riso e soia', 'Mortadella IGP', 'Stracciatella di bufala', 'Pistacchi di Bronte'],
        isSignature: true,
        iconName: 'local_pizza',
      ),
      MenuItem(
        id: 'm_12',
        name: 'Tagliere Antigravity',
        description: 'Selezione di formaggi erborinati, pecorino toscano, salumi artigianali, miele di castagno e noci.',
        price: 14.00,
        category: MenuCategory.snack,
        ingredients: ['Pecorino toscano', 'Formaggio erborinato', 'Salame artigianale', 'Prosciutto crudo di Parma', 'Miele di castagno', 'Noci'],
        iconName: 'dinner_dining',
      ),
    ];
  }

  // Populate Mock Rewards Catalog
  void _initRewards() {
    _rewards = [
      Reward(
        id: 'rew_1',
        title: 'Espresso d\'Autore',
        description: 'Un espresso speciale a scelta tra le nostre monorigini esclusive della settimana.',
        pointsCost: 100,
        iconName: 'local_cafe',
        terms: 'Valido tutti i giorni. Riscatto soggetto a disponibilità delle monorigini.',
      ),
      Reward(
        id: 'rew_2',
        title: 'Croissant Artigianale',
        description: 'Un friabile cornetto sfogliato al burro con la farcitura premium che preferisci.',
        pointsCost: 150,
        iconName: 'bakery_dining',
        terms: 'Valido per consumazione al banco o asporto. Scade 30 giorni dopo il riscatto.',
      ),
      Reward(
        id: 'rew_3',
        title: 'Cocktail Signature',
        description: 'Un delizioso cocktail d\'autore preparato e servito dai nostri esperti mixologist.',
        pointsCost: 500,
        iconName: 'local_bar',
        terms: 'Utilizzabile dalle ore 18:00 in poi. Riservato ai maggiorenni.',
      ),
      Reward(
        id: 'rew_4',
        title: 'Aperitivo Monet x2',
        description: 'Un ricco tagliere gourmet per due persone accompagnato da due drink o calici a scelta.',
        pointsCost: 1000,
        iconName: 'dinner_dining',
        terms: 'È gradita la prenotazione. Consumabile solo al tavolo.',
      ),
    ];
  }
}
