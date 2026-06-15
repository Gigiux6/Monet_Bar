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
  static const int _maxAuthAttempts = 5;
  static const Duration _authWindow = Duration(minutes: 15);

  static const int _maxGeneralRequests = 30;
  static const Duration _generalWindow = Duration(minutes: 1);

  // --- STATO IN-MEMORY PER I LIMITI GENERALI (Altissime Performance) ---
  final List<DateTime> _generalRequestsTimestamps = [];

  // --- HELPER PER AUTH (SharedPreferences) ---
  Future<void> _cleanOldAuthTimestamps(SharedPreferences prefs) async {
    final now = DateTime.now();
    final List<String> timestampsStr = prefs.getStringList(_authFailedKey) ?? [];
    
    final validTimestamps = timestampsStr.where((ts) {
      final dateTime = DateTime.tryParse(ts);
      if (dateTime == null) return false;
      return now.difference(dateTime) <= _authWindow;
    }).toList();

    if (validTimestamps.length != timestampsStr.length) {
      await prefs.setStringList(_authFailedKey, validTimestamps);
    }
  }

  // --- AUTENTICAZIONE (Manteniamo la persistenza sul disco) ---

  Future<void> checkAuthLimit() async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanOldAuthTimestamps(prefs);
    
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

  Future<void> recordAuthFailure() async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanOldAuthTimestamps(prefs);
    
    final List<String> timestampsStr = prefs.getStringList(_authFailedKey) ?? [];
    timestampsStr.add(DateTime.now().toIso8601String());
    await prefs.setStringList(_authFailedKey, timestampsStr);
  }

  Future<void> resetAuthFailures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authFailedKey);
  }

  // --- RICHIESTE GENERALI (Spostate in RAM per evitare I/O su disco) ---

  Future<void> checkGeneralLimit() async {
    final now = DateTime.now();
    
    // Pulisce in un istante le date vecchie direttamente in memoria
    _generalRequestsTimestamps.removeWhere((dateTime) => now.difference(dateTime) > _generalWindow);

    if (_generalRequestsTimestamps.length >= _maxGeneralRequests) {
      throw RateLimitExceededException(
        'Troppe richieste effettuate. Attendi un momento prima di riprovare.',
      );
    }

    _generalRequestsTimestamps.add(now);
  }
}
