import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'rate_limiter_service.dart';
import 'notification_service.dart';

/// Custom exception for account linking
class NeedsPasswordForLinkingException implements Exception {
  final AuthCredential credential;
  final String email;
  NeedsPasswordForLinkingException(this.credential, this.email);
}

/// A service to manage authentication using Firebase Auth.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Stream mapping Firebase Auth state changes to UserModel.
  /// It automatically fetches the Firestore user document to retrieve the points balance.
  Stream<UserModel?> get userStateChanges {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);

      return _db.collection('users').doc(firebaseUser.uid).snapshots().map((userDoc) {
        if (userDoc.exists) {
          return UserModel.fromMap({
            'id': firebaseUser.uid,
            ...userDoc.data()!,
          });
        } else {
          // If the profile document doesn't exist yet (e.g. during registration),
          // return a temporary model. The actual registration methods will create it.
          return UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Cliente Monet',
            email: firebaseUser.email ?? '',
            pointsBalance: 0,
            isTemporary: true,
          );
        }
      });
    });
  }

  /// Get the current authenticated user mapped to UserModel.
  UserModel? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Cliente Monet',
      email: firebaseUser.email ?? '',
      pointsBalance: 0, // Points require fetching asynchronously, use stream for real-time points.
    );
  }

  /// Sign in using Email and Password with friendly error mapping.
  Future<UserModel?> login(String email, String password) async {
    await RateLimiterService().checkAuthLimit();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) return null;
      
      // Retrieve the user model from Firestore
      final userDoc = await _db.collection('users').doc(credential.user!.uid).get();
      
      // Iscrizione al topic utente per Notifiche Push Personali
      NotificationService().subscribeToUserTopic(credential.user!.uid);

      if (userDoc.exists) {
        return UserModel.fromMap({
          'id': credential.user!.uid,
          ...userDoc.data()!,
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      await RateLimiterService().recordAuthFailure();
      throw _mapFirebaseAuthError(e);
    } on RateLimitExceededException {
      rethrow;
    } catch (e) {
      await RateLimiterService().recordAuthFailure();
      throw 'Errore generico: $e';
    }
  }

  /// Sign out.
  Future<void> logout() async {
    final user = _auth.currentUser;
    if (user != null) {
      await NotificationService().unsubscribeFromUserTopic(user.uid);
    }
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Resolves an email from a username. Returns null if not found.
  Future<String?> resolveEmailFromUsername(String username) async {
    try {
      final doc = await _db.collection('usernames').doc(username).get();
      if (doc.exists) {
        return doc.data()?['email'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Checks if a username is already taken.
  Future<bool> isUsernameTaken(String username) async {
    try {
      final doc = await _db.collection('usernames').doc(username).get();
      return doc.exists;
    } catch (e) {
      return true; // fail-safe
    }
  }

  /// Invia l'email per il recupero della password
  Future<void> resetPassword(String email) async {
    await RateLimiterService().checkAuthLimit();
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      await RateLimiterService().recordAuthFailure();
      throw _mapFirebaseAuthError(e);
    } on RateLimitExceededException {
      rethrow;
    } catch (e) {
      await RateLimiterService().recordAuthFailure();
      throw 'Errore durante il recupero password: $e';
    }
  }

  /// Register using Username, Email and Password with points initialization and error mapping.
  Future<UserModel?> register(String username, String email, String password) async {
    await RateLimiterService().checkAuthLimit();
    try {
      final isTaken = await isUsernameTaken(username);
      if (isTaken) {
        throw 'Il nome utente "$username" è già in uso. Scegline un altro.';
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) return null;
      
      // Invia l'email di verifica
      await credential.user!.sendEmailVerification();
      
      final newUser = UserModel(
        id: credential.user!.uid,
        name: username,
        email: email,
        pointsBalance: 0,
      );
      
      await _db.collection('usernames').doc(username).set({
        'email': email,
        'uid': credential.user!.uid,
      });

      await _db.collection('users').doc(credential.user!.uid).set(newUser.toMap());
      
      // Iscrizione al topic utente per Notifiche Push Personali
      NotificationService().subscribeToUserTopic(credential.user!.uid);

      return newUser;
    } on FirebaseAuthException catch (e) {
      await RateLimiterService().recordAuthFailure();
      throw _mapFirebaseAuthError(e);
    } on RateLimitExceededException {
      rethrow;
    } catch (e) {
      if (e is RateLimitExceededException) rethrow;
      if (e is String && e.startsWith('Il nome utente')) throw e; // Don't record failure for username taken
      await RateLimiterService().recordAuthFailure();
      if (e is String) throw e;
      throw 'Errore generico: $e';
    }
  }

  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    await RateLimiterService().checkAuthLimit();
    GoogleSignInAccount? googleUser;
    AuthCredential? credential;
    try {
      print('--- STARTING GOOGLE SIGN IN ---');
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
        print('Firebase Auth credential created successfully (Web Popup)');
      } else {
        googleUser = await GoogleSignIn().signIn();
        
        print('Google User: ${googleUser?.email}');
        if (googleUser == null) {
          print('--- L\'utente ha annullato il login o l\'API ha fallito silenziosamente ---');
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        print('Google Auth retrieved successfully');
        
        credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
        print('Firebase Auth credential created successfully');
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      // Workaround for Flutter Web Firestore websocket sync delay after OAuth sign in
      // Using snapshots().first instead of get() often bypasses the silent hang bug
      final userDoc = await _db.collection('users').doc(firebaseUser.uid).snapshots().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw 'La connessione al database sta impiegando troppo tempo. Riprova.',
      );
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final userModel = UserModel.fromMap({
          'id': firebaseUser.uid,
          ...data,
        });
        
        if (data['hasGoogleAuth'] != true) {
          // Primo login Google per un account pre-esistente (Auto-Link)
          await _db.collection('users').doc(firebaseUser.uid).update({'hasGoogleAuth': true}).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw 'Timeout aggiornamento dati utente. Riprova.',
          );
          userModel.isAutoLinked = true;
        }
        
        // Iscrizione al topic utente per Notifiche Push Personali
        NotificationService().subscribeToUserTopic(firebaseUser.uid);

        return userModel;
      }

      // Se l'utente non esiste, procediamo con la registrazione silente.
      // 1. Genera Username
      String baseUsername = (firebaseUser.displayName?.isNotEmpty ?? false)
          ? firebaseUser.displayName!.replaceAll(' ', '_').toLowerCase()
          : (firebaseUser.email?.split('@')[0] ?? 'user').toLowerCase();
      
      baseUsername = baseUsername.replaceAll(RegExp(r'[^a-z0-9_]'), '');
      if (baseUsername.isEmpty) baseUsername = 'user';

      // 2. Risolvi i conflitti di Username
      String finalUsername = baseUsername;
      int counter = 1;
      while (await isUsernameTaken(finalUsername)) {
        finalUsername = '$baseUsername$counter';
        counter++;
      }

      // 3. Crea utente e mappa Username
      final newUser = UserModel(
        id: firebaseUser.uid,
        name: finalUsername,
        email: firebaseUser.email ?? '',
        pointsBalance: 0, // Inizializza i punti a 0 per le regole Firestore
      );

      await _db.collection('usernames').doc(finalUsername).set({
        'email': firebaseUser.email ?? '',
        'uid': firebaseUser.uid,
      });

      await _db.collection('users').doc(firebaseUser.uid).set({
        ...newUser.toMap(),
        'hasGoogleAuth': true,
      });

      // Iscrizione al topic utente per Notifiche Push Personali
      NotificationService().subscribeToUserTopic(firebaseUser.uid);

      return newUser;
    } on FirebaseAuthException catch (e, stacktrace) {
      print('--- ERROR DURING GOOGLE SIGN IN (FirebaseAuthException) ---');
      print('Error Code: ${e.code}');
      print('Error Details: $e');
      print('Stacktrace: $stacktrace');
      print('-----------------------------------');
      if (e.code == 'account-exists-with-different-credential') {
        final email = googleUser?.email ?? e.email ?? '';
        final cred = credential ?? e.credential;
        if (cred != null) {
          throw NeedsPasswordForLinkingException(
            cred,
            email,
          );
        }
      }
      await RateLimiterService().recordAuthFailure();
      throw _mapFirebaseAuthError(e);
    } on RateLimitExceededException {
      rethrow;
    } catch (e, stacktrace) {
      print('--- ERROR DURING GOOGLE SIGN IN (Generic) ---');
      print('Error Type: ${e.runtimeType}');
      print('Error Details: $e');
      print('Stacktrace: $stacktrace');
      print('-----------------------------------');
      if (e is RateLimitExceededException) rethrow;
      await RateLimiterService().recordAuthFailure();
      throw 'Errore durante l\'accesso con Google: $e';
    }
  }

  /// Sign in with Facebook
  Future<UserModel?> signInWithFacebook() async {
    await RateLimiterService().checkAuthLimit();
    try {
      print('--- STARTING FACEBOOK SIGN IN ---');
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final credential = FacebookAuthProvider.credential(accessToken.tokenString);

        final userCredential = await _auth.signInWithCredential(credential);
        final firebaseUser = userCredential.user;
        if (firebaseUser == null) return null;

        // Workaround for Flutter Web Firestore websocket sync delay
        final userDoc = await _db.collection('users').doc(firebaseUser.uid).snapshots().first.timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw 'La connessione al database sta impiegando troppo tempo. Riprova.',
        );

        if (userDoc.exists) {
          final data = userDoc.data()!;
          final userModel = UserModel.fromMap({
            'id': firebaseUser.uid,
            ...data,
          });

          if (data['hasFacebookAuth'] != true) {
            await _db.collection('users').doc(firebaseUser.uid).update({'hasFacebookAuth': true}).timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw 'Timeout aggiornamento dati utente. Riprova.',
            );
            userModel.isAutoLinked = true;
          }

          NotificationService().subscribeToUserTopic(firebaseUser.uid);
          return userModel;
        }

        // Se l'utente non esiste, procediamo con la registrazione silente.
        String baseUsername = (firebaseUser.displayName?.isNotEmpty ?? false)
            ? firebaseUser.displayName!.replaceAll(' ', '_').toLowerCase()
            : (firebaseUser.email?.split('@')[0] ?? 'fb_user').toLowerCase();
        
        baseUsername = baseUsername.replaceAll(RegExp(r'[^a-z0-9_]'), '');
        if (baseUsername.isEmpty) baseUsername = 'fb_user';

        String finalUsername = baseUsername;
        int counter = 1;
        while (await isUsernameTaken(finalUsername)) {
          finalUsername = '$baseUsername$counter';
          counter++;
        }

        final newUser = UserModel(
          id: firebaseUser.uid,
          name: finalUsername,
          email: firebaseUser.email ?? '',
          pointsBalance: 0,
        );

        await _db.collection('usernames').doc(finalUsername).set({
          'email': firebaseUser.email ?? '',
          'uid': firebaseUser.uid,
        });

        await _db.collection('users').doc(firebaseUser.uid).set({
          ...newUser.toMap(),
          'hasFacebookAuth': true,
        });

        NotificationService().subscribeToUserTopic(firebaseUser.uid);

        return newUser;
      } else if (result.status == LoginStatus.cancelled) {
        print('--- FACEBOOK LOGIN CANCELLED ---');
        return null;
      } else {
        throw result.message ?? 'Errore sconosciuto';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw 'Hai già un account con questa email. Accedi con Google o Email/Password per collegare Facebook.';
      }
      await RateLimiterService().recordAuthFailure();
      throw _mapFirebaseAuthError(e);
    } on RateLimitExceededException {
      rethrow;
    } catch (e) {
      if (e is RateLimitExceededException) rethrow;
      await RateLimiterService().recordAuthFailure();
      throw 'Errore durante l\'accesso con Facebook: $e';
    }
  }

  /// Link an existing email/password account with a Google credential
  Future<UserModel?> linkGoogleAccount(String email, String password, AuthCredential credential) async {
    try {
      // 1. Sign in with the existing email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Link the Google credential
      await userCredential.user?.linkWithCredential(credential);

      // 3. Return the user model
      final userDoc = await _db.collection('users').doc(userCredential.user!.uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap({
          'id': userCredential.user!.uid,
          ...userDoc.data()!,
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      throw 'Errore durante il collegamento account: $e';
    }
  }

  /// Delete the current user's account and data.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw 'Utente non autenticato.';

    try {
      // 1. Get username to delete it from usernames collection
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final username = userDoc.data()?['name'] as String?;

      // 2. Fetch all user transactions and coupons to delete them
      final transactionsSnapshot = await _db.collection('users').doc(user.uid).collection('transactions').get();
      final couponsSnapshot = await _db.collection('coupons').where('userId', isEqualTo: user.uid).get();

      // 3. Delete Firestore data via batch
      final batch = _db.batch();
      if (username != null && username.isNotEmpty) {
        batch.delete(_db.collection('usernames').doc(username));
      }
      batch.delete(_db.collection('users').doc(user.uid));

      // Delete transactions
      for (var doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete coupons
      for (var doc in couponsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // 3. Delete auth account
      await user.delete();

      // Clear Google session if present
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      
      // Clear Facebook session if present
      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {}
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Per motivi di sicurezza, fai il logout e accedi di nuovo prima di eliminare l\'account.';
      }
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      throw 'Errore durante l\'eliminazione dell\'account: $e';
    }
  }

  /// Updates the user's username in both /usernames and /users collections.
  Future<void> updateUsername(String newUsername, String oldUsername) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Utente non autenticato.';
    
    if (newUsername.trim().isEmpty) throw 'Il nome utente non può essere vuoto.';
    if (newUsername == oldUsername) return;

    final isTaken = await isUsernameTaken(newUsername);
    if (isTaken) {
      throw 'Questo Username è già in uso.';
    }

    final batch = _db.batch();

    // 1. Crea il nuovo documento in /usernames
    final newUsernameRef = _db.collection('usernames').doc(newUsername);
    batch.set(newUsernameRef, {
      'email': user.email ?? '',
      'uid': user.uid,
    });

    // 2. Elimina il vecchio documento in /usernames
    if (oldUsername.isNotEmpty) {
      final oldUsernameRef = _db.collection('usernames').doc(oldUsername);
      batch.delete(oldUsernameRef);
    }

    // 3. Aggiorna il nome nel documento in /users
    final userRef = _db.collection('users').doc(user.uid);
    batch.update(userRef, {'name': newUsername});

    await batch.commit();
  }

  /// Map Firebase Auth exceptions to friendly Italian error messages (from Guess Me logic).
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email o password errate. Riprova.';
      case 'email-already-in-use':
        return 'Questa email è già registrata. Prova ad accedere, oppure usa "Accedi con Google".';
      case 'weak-password':
        return 'La password deve contenere almeno 8 caratteri, una lettera maiuscola e un numero.';
      case 'invalid-email':
        return 'Inserisci un indirizzo email valido.';
      default:
        return e.message ?? e.toString();
    }
  }
}
