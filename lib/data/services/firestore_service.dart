import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/menu_model.dart';
import '../models/reward_model.dart';
import '../models/coupon_model.dart';
import '../models/transaction_model.dart';

/// A service to handle all Cloud Firestore operations.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Fetch all menu items from the 'menu_items' collection.
  Stream<List<MenuItem>> get menuItemsStream {
    return _db.collection('menu_items')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItem.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Fetch the rewards catalog from the 'rewards' collection.
  Stream<List<Reward>> get rewardsStream {
    return _db.collection('rewards')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reward.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of active and used coupons for the current logged-in user.
  Stream<List<Coupon>> get couponsStream {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    
    return _db.collection('coupons')
        .where('userId', isEqualTo: userId)
        .orderBy('claimDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Coupon.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  /// Stream of point transactions for the current logged-in user.
  Stream<List<TransactionModel>> get transactionsStream {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    
    return _db.collection('users').doc(userId).collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  /// Add a new item to the menu.
  Future<void> addMenuItem(MenuItem item) async {
    try {
      final docRef = _db.collection('menu_items').doc();
      final map = item.toMap();
      map['id'] = docRef.id;
      await docRef.set(map);
    } catch (e) {
      print("Errore nell'aggiunta del prodotto: $e");
      throw e;
    }
  }

  /// Update an existing menu item
  Future<void> updateMenuItem(MenuItem item) async {
    try {
      await _db.collection('menu_items').doc(item.id).update(item.toMap());
    } catch (e) {
      print("Errore nell'aggiornamento del prodotto: $e");
      throw e;
    }
  }

  /// Delete a menu item
  Future<void> deleteMenuItem(String id) async {
    try {
      await _db.collection('menu_items').doc(id).delete();
    } catch (e) {
      print("Errore nell'eliminazione del prodotto: $e");
      throw e;
    }
  }

  /// Add a new reward to the catalog.
  Future<void> addReward(Reward reward) async {
    final docRef = _db.collection('rewards').doc();
    final map = reward.toMap();
    map['id'] = docRef.id;
    await docRef.set(map);
  }

  /// Update an existing reward
  Future<void> updateReward(Reward reward) async {
    try {
      await _db.collection('rewards').doc(reward.id).update(reward.toMap());
    } catch (e) {
      print("Errore nell'aggiornamento del premio: $e");
      throw e;
    }
  }

  /// Delete a reward
  Future<void> deleteReward(String id) async {
    try {
      await _db.collection('rewards').doc(id).delete();
    } catch (e) {
      print("Errore nell'eliminazione del premio: $e");
      throw e;
    }
  }

  /// Add points to a user profile and record a transaction in the new subcollection.
  /// (Smart Points Engine based on Euro spent).
  Future<bool> addPointsByUsername(String username, double amountSpent, String description) async {
    try {
      // Fase A (Lookup): Interroga la collezione /usernames/{username} per recuperare l'UID reale
      final usernameDoc = await _db.collection('usernames').doc(username).get();
      if (!usernameDoc.exists) throw 'Cliente non trovato';
      
      final userId = usernameDoc.data()?['uid'] as String?;
      if (userId == null) throw 'UID non trovato per questo utente';

      // Fase B (Calcolo): 1 Euro = 1 Punto arrotondato per difetto
      final points = amountSpent.floor();
      if (points <= 0) throw 'Importo troppo basso per generare punti (minimo 1€)';

      final adminId = _auth.currentUser?.uid ?? 'unknown_admin';

      // Fase C (Salvataggio Transazionale)
      final userRef = _db.collection('users').doc(userId);
      final txRef = userRef.collection('transactions').doc();

      await _db.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) throw 'Profilo utente non trovato nel database principale';
        
        int currentPoints = userSnapshot.data()?['points'] ?? userSnapshot.data()?['pointsBalance'] ?? 0;
        final updatedPoints = currentPoints + points;
        transaction.update(userRef, {'points': updatedPoints});

        // Crea nuovo documento nella sottocollezione
        final transactionData = TransactionModel(
          id: txRef.id,
          userId: userId,
          points: points,
          type: 'add',
          description: description,
          date: DateTime.now(),
        );
        
        final txMap = transactionData.toMap();
        txMap['amountSpent'] = amountSpent;
        txMap['adminId'] = adminId;
        
        transaction.set(txRef, txMap);
      });

      return true;
    } catch (e) {
      print("Errore nell'aggiunta punti: $e");
      throw e; // Rilancia per mostrare l'errore in UI
    }
  }

  /// Redeem a reward. Deducts points and generates a coupon atomically.
  Future<Map<String, dynamic>> redeemReward(Reward reward) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {'success': false, 'message': 'Utente non autenticato'};
    }

    try {
      final userRef = _db.collection('users').doc(userId);
      final couponRef = _db.collection('coupons').doc();
      final txRef = userRef.collection('transactions').doc();

      final result = await _db.runTransaction<Map<String, dynamic>>((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          return {'success': false, 'message': 'Profilo utente non trovato'};
        }

        final currentPoints = userSnapshot.data()?['points'] ?? userSnapshot.data()?['pointsBalance'] ?? 0;
        if (currentPoints < reward.pointsCost) {
          return {'success': false, 'message': 'Punti insufficienti per questo premio'};
        }

        // 1. Deduct points from user balance
        final newBalance = currentPoints - reward.pointsCost;
        transaction.update(userRef, {'points': newBalance});

        // 2. Create the coupon
        final couponId = 'CPN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${reward.id.toUpperCase()}';
        final coupon = Coupon(
          id: couponId,
          rewardId: reward.id,
          rewardTitle: reward.title,
          pointsSpent: reward.pointsCost,
          userId: userId,
          claimDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          status: 'active',
        );
        transaction.set(couponRef, coupon.toMap());

        // 3. Write points transaction log
        final tx = TransactionModel(
          id: txRef.id,
          userId: userId,
          points: reward.pointsCost,
          type: 'redeem',
          description: 'Riscatto ${reward.title}',
          date: DateTime.now(),
        );
        transaction.set(txRef, tx.toMap());

        return {'success': true, 'coupon': coupon};
      });

      return result;
    } catch (e) {
      print("Errore nel riscatto del premio: $e");
      return {'success': false, 'message': 'Si è verificato un errore: $e'};
    }
  }

  /// Admin redeems a reward on behalf of a client using a QR code
  Future<Map<String, dynamic>> adminRedeemReward(String clientId, String rewardId) async {
    try {
      final rewardDoc = await _db.collection('rewards').doc(rewardId).get();
      if (!rewardDoc.exists) return {'success': false, 'message': 'Premio non trovato'};
      
      final rewardData = rewardDoc.data()!;
      final pointsCost = ((rewardData['pointsCost'] ?? rewardData['pointsRequired'] ?? 0) as num).toInt();
      final rewardTitle = rewardData['title'] as String;

      final userRef = _db.collection('users').doc(clientId);
      final couponRef = _db.collection('coupons').doc();
      final txRef = userRef.collection('transactions').doc();

      final result = await _db.runTransaction<Map<String, dynamic>>((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          return {'success': false, 'message': 'Profilo cliente non trovato'};
        }

        final currentPoints = userSnapshot.data()?['points'] ?? userSnapshot.data()?['pointsBalance'] ?? 0;
        if (currentPoints < pointsCost) {
          return {'success': false, 'message': 'Il cliente non ha abbastanza punti ($currentPoints/$pointsCost)'};
        }

        // 1. Deduct points from user balance
        final newBalance = currentPoints - pointsCost;
        transaction.update(userRef, {'points': newBalance});

        // 2. Create the coupon (already used, since it's delivered at the counter)
        final couponId = 'CPN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${rewardId.toUpperCase()}';
        final coupon = Coupon(
          id: couponId,
          rewardId: rewardId,
          rewardTitle: rewardTitle,
          pointsSpent: pointsCost,
          userId: clientId,
          claimDate: DateTime.now(),
          expiryDate: DateTime.now(),
          status: 'used',
        );
        transaction.set(couponRef, coupon.toMap());

        // 3. Write points transaction log
        final tx = TransactionModel(
          id: txRef.id,
          userId: clientId,
          points: pointsCost,
          type: 'redeem',
          description: 'Riscatto $rewardTitle',
          date: DateTime.now(),
        );
        transaction.set(txRef, tx.toMap());

        return {'success': true, 'rewardTitle': rewardTitle};
      });

      return result;
    } catch (e) {
      print("Errore nel riscatto admin del premio: $e");
      return {'success': false, 'message': 'Si è verificato un errore: $e'};
    }
  }

  /// Validate a coupon. Updates coupon status to 'used'.
  /// Used by the barista when validating a coupon presented by the customer.
  Future<bool> validateCoupon(String couponId) async {
    try {
      // Find the coupon document by code field or document ID
      final querySnapshot = await _db.collection('coupons')
          .where('id', isEqualTo: couponId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return false;

      final docRef = querySnapshot.docs.first.reference;
      final docData = querySnapshot.docs.first.data();

      if (docData['status'] != 'active') {
        // Already used or expired
        return false;
      }

      await docRef.update({
        'status': 'used',
        'validatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print("Errore nella validazione del coupon: $e");
      return false;
    }
  }
}
