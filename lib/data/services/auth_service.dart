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
            points: 0,
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
      points: 0, // Points require fetching asynchronously, use stream for real-time points.
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
      await GoogleSignIn().signOut().timeout(const Duration(seconds: 2));
      await GoogleSignIn().disconnect().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut().timeout(const Duration(seconds: 2));
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

  /// Modifica la password dell'utente. Richiede la vecchia password per ri-autenticazione.
  /// Controlla anche che l'utente stia usando l'autenticazione tramite email/password.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await RateLimiterService().checkAuthLimit();
    final user = _auth.currentUser;
    
    if (user == null) {
      throw 'Utente non autenticato.';
    }
    if (user.email == null || user.email!.isEmpty) {
      throw 'Il tuo account non utilizza un indirizzo email.';
    }

    // Controlla se è loggato con social
    final providerData = user.providerData;
    final isEmailProvider = providerData.any((p) => p.providerId == 'password');
    if (!isEmailProvider) {
      throw "Non puoi modificare la password perché hai effettuato l'accesso con Google o Facebook.";
    }

    try {
      // Ri-autenticazione
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Aggiornamento password
      await user.updatePassword(newPassword);
      
    } on FirebaseAuthException catch (e) {
      await RateLimiterService().recordAuthFailure();
      throw _mapFirebaseAuthError(e);
    } on RateLimitExceededException {
      rethrow;
    } catch (e) {
      await RateLimiterService().recordAuthFailure();
      throw 'Errore durante la modifica della password: $e';
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
        points: 0,
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
    AuthCredential? credential;
    GoogleSignInAccount? googleUser;
    try {
      print('--- STARTING GOOGLE SIGN IN ---');
      late UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
        print('Firebase Auth credential created successfully (Web Popup)');
        await RateLimiterService().checkAuthLimit();
      } else {
        googleUser = await GoogleSignIn().signIn();
        
        print('Google User: ${googleUser?.email}');
        if (googleUser == null) {
          print('--- GOOGLE SIGN IN CANCELLED ---');
          return null;
        }

        await RateLimiterService().checkAuthLimit();

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

      return await _handleOAuthUserSync(firebaseUser, authProviderKey: 'hasGoogleAuth');
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
    try {
      print('--- STARTING FACEBOOK SIGN IN ---');
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        await RateLimiterService().checkAuthLimit();
        final AccessToken accessToken = result.accessToken!;
        final credential = FacebookAuthProvider.credential(accessToken.tokenString);

        final userCredential = await _auth.signInWithCredential(credential);
        final firebaseUser = userCredential.user;
        if (firebaseUser == null) return null;

        return await _handleOAuthUserSync(firebaseUser, authProviderKey: 'hasFacebookAuth');
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

  /// Deletes the current user's account and all their data.
  Future<void> deleteAccount() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) throw 'Utente non autenticato.';

    // Controllo preventivo: se l'accesso è avvenuto più di 5 minuti fa, Firebase Auth rifiuterà l'eliminazione.
    // Fermiamo l'operazione prima di toccare Firestore.
    final lastSignIn = firebaseUser.metadata.lastSignInTime;
    if (lastSignIn != null && DateTime.now().difference(lastSignIn).inMinutes > 5) {
      throw 'Per motivi di sicurezza, effettua il logout e accedi di nuovo prima di eliminare l\'account.';
    }

    try {
      // Step 1: Fetch all Firestore data to delete
      final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();
      final username = userDoc.data()?['name'] as String?;
      final transactionsSnapshot = await _db.collection('users').doc(firebaseUser.uid).collection('transactions').get();
      final couponsSnapshot = await _db.collection('coupons').where('userId', isEqualTo: firebaseUser.uid).get();

      // Step 2: Delete all Firestore data in a batch
      final batch = _db.batch();
      if (username != null && username.isNotEmpty) {
        batch.delete(_db.collection('usernames').doc(username));
      }
      batch.delete(_db.collection('users').doc(firebaseUser.uid));
      for (var doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in couponsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Step 3: Delete the Firebase Auth account
      await firebaseUser.delete();

      // Step 4: Clear social sessions
      try { await GoogleSignIn().signOut(); } catch (_) {}
      try { await FacebookAuth.instance.logOut(); } catch (_) {}

    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Per motivi di sicurezza, effettua il logout e accedi di nuovo prima di eliminare l\'account.';
      }
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      if (e is String) rethrow;
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

  /// Gestisce la creazione o l'aggiornamento del profilo su Firestore dopo un login OAuth.
  Future<UserModel> _handleOAuthUserSync(User firebaseUser, {required String authProviderKey}) async {
    // 1. Controlla se l'utente esiste già
    final userDoc = await _db.collection('users').doc(firebaseUser.uid).snapshots().first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw 'La connessione al database sta impiegando troppo tempo. Riprova.',
    );

    if (userDoc.exists) {
      final data = userDoc.data()!;
      var userModel = UserModel.fromMap({'id': firebaseUser.uid, ...data});

      // Aggiorna il flag del provider se mancante (Auto-Link)
      if (data[authProviderKey] != true) {
        await _db.collection('users').doc(firebaseUser.uid).update({authProviderKey: true}).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw 'Timeout aggiornamento dati utente. Riprova.',
        );
        userModel = userModel.copyWith(isAutoLinked: true);
      }
      NotificationService().subscribeToUserTopic(firebaseUser.uid);
      return userModel;
    }

    // 2. L'utente non esiste: Generazione Username Silente
    String baseUsername = (firebaseUser.displayName?.isNotEmpty ?? false)
        ? firebaseUser.displayName!.replaceAll(' ', '_').toLowerCase()
        : (firebaseUser.email?.split('@')[0] ?? 'user').toLowerCase();
    
    baseUsername = baseUsername.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (baseUsername.isEmpty) baseUsername = 'user';

    String finalUsername = baseUsername;
    int counter = 1;
    
    while (await isUsernameTaken(finalUsername)) {
      finalUsername = '$baseUsername$counter';
      counter++;
    }

    // 3. Creazione del nuovo profilo
    final newUser = UserModel(
      id: firebaseUser.uid,
      name: finalUsername,
      email: firebaseUser.email ?? '',
      points: 0,
    );

    final batch = _db.batch();
    batch.set(_db.collection('usernames').doc(finalUsername), {
      'email': firebaseUser.email ?? '',
      'uid': firebaseUser.uid,
    });
    batch.set(_db.collection('users').doc(firebaseUser.uid), {
      ...newUser.toMap(),
      authProviderKey: true,
    });
    await batch.commit();

    NotificationService().subscribeToUserTopic(firebaseUser.uid);
    return newUser;
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
