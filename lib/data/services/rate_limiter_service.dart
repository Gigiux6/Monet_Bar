import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RateLimitExceededException implements Exception {
  final String message;
  RateLimitExceededException(this.message);
  @override
  String toString() => message;
}

class RateLimiterService {
  static final RateLimiterService _instance = RateLimiterService._internal();
  factory RateLimiterService() => _instance;
  RateLimiterService._internal();

  static const String _authFailedKey = 'auth_failed_timestamps';
  static const String _generalRequestsKey = 'general_requests_timestamps';

  static const int _maxAuthAttempts = 5;
  static const Duration _authWindow = Duration(minutes: 15);

  static const int _maxGeneralRequests = 30;
  static const Duration _generalWindow = Duration(minutes: 1);

  Future<void> _cleanOldTimestamps(SharedPreferences prefs, String key, Duration window) async {
    final now = DateTime.now();
    final List<String> timestampsStr = prefs.getStringList(key) ?? [];
    
    final validTimestamps = timestampsStr.where((ts) {
      final dateTime = DateTime.tryParse(ts);
      if (dateTime == null) return false;
      return now.difference(dateTime) <= window;
    }).toList();

    if (validTimestamps.length != timestampsStr.length) {
      await prefs.setStringList(key, validTimestamps);
    }
  }

  /// Verifica se è possibile effettuare un tentativo di autenticazione.
  /// Se bloccato, lancia una RateLimitExceededException.
  Future<void> checkAuthLimit() async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanOldTimestamps(prefs, _authFailedKey, _authWindow);
    
    final List<String> timestampsStr = prefs.getStringList(_authFailedKey) ?? [];
    if (timestampsStr.length >= _maxAuthAttempts) {
      final oldest = DateTime.tryParse(timestampsStr.first);
      if (oldest != null) {
        final waitTime = _authWindow - DateTime.now().difference(oldest);
        final waitMinutes = waitTime.inMinutes;
        throw RateLimitExceededException(
          'Troppi tentativi falliti. Riprova tra ${waitMinutes > 0 ? waitMinutes : 1} minuti.',
        );
      } else {
        throw RateLimitExceededException('Troppi tentativi falliti. Riprova più tardi.');
      }
    }
  }

  /// Registra un tentativo fallito di autenticazione.
  Future<void> recordAuthFailure() async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanOldTimestamps(prefs, _authFailedKey, _authWindow);
    
    final List<String> timestampsStr = prefs.getStringList(_authFailedKey) ?? [];
    timestampsStr.add(DateTime.now().toIso8601String());
    await prefs.setStringList(_authFailedKey, timestampsStr);
  }

  /// Azzera i tentativi falliti di autenticazione (es. in caso di login con successo opzionale, 
  /// anche se non strettamente necessario).
  Future<void> resetAuthFailures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authFailedKey);
  }

  /// Verifica e registra una chiamata generica agli endpoint (Firestore/Functions).
  /// Se bloccato, lancia una RateLimitExceededException.
  Future<void> checkGeneralLimit() async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanOldTimestamps(prefs, _generalRequestsKey, _generalWindow);

    final List<String> timestampsStr = prefs.getStringList(_generalRequestsKey) ?? [];
    if (timestampsStr.length >= _maxGeneralRequests) {
      throw RateLimitExceededException(
        'Troppe richieste effettuate. Attendi un momento prima di riprovare.',
      );
    }

    timestampsStr.add(DateTime.now().toIso8601String());
    await prefs.setStringList(_generalRequestsKey, timestampsStr);
  }
}
