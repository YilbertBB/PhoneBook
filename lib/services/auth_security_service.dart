import 'package:shared_preferences/shared_preferences.dart';

class AuthSecurityService {
  static const String _attemptsKey = 'login_attempts';
  static const String _lastAttemptKey = 'last_login_attempt';
  static const String _lockoutUntilKey = 'lockout_until';
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  Future<bool> canAttemptLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_attemptsKey) ?? 0;
    final lockoutUntil = prefs.getString(_lockoutUntilKey);

    // Si está en periodo de bloqueo
    if (lockoutUntil != null) {
      final lockoutTime = DateTime.parse(lockoutUntil);
      final now = DateTime.now();

      if (now.isBefore(lockoutTime)) {
        return false; // Still locked out
      } else {
        // Reset attempts after lockout period
        await prefs.setInt(_attemptsKey, 0);
        await prefs.remove(_lockoutUntilKey);
      }
    }

    return attempts < _maxAttempts;
  }

  Future<void> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_attemptsKey) ?? 0) + 1;

    await prefs.setInt(_attemptsKey, attempts);
    await prefs.setString(_lastAttemptKey, DateTime.now().toIso8601String());

    // Si excede los intentos máximos, activar bloqueo
    if (attempts >= _maxAttempts) {
      final lockoutUntil = DateTime.now().add(_lockoutDuration);
      await prefs.setString(_lockoutUntilKey, lockoutUntil.toIso8601String());
    }
  }

  Future<void> resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_attemptsKey, 0);
    await prefs.remove(_lastAttemptKey);
    await prefs.remove(_lockoutUntilKey);
  }

  Future<int> getRemainingAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_attemptsKey) ?? 0;
    return _maxAttempts - attempts;
  }

  Future<DateTime?> getLockoutTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = prefs.getString(_lockoutUntilKey);
    return lockoutUntil != null ? DateTime.parse(lockoutUntil) : null;
  }

  Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_attemptsKey) ?? 0;
  }

  Future<bool> isLockedOut() async {
    final lockoutTime = await getLockoutTime();
    if (lockoutTime == null) return false;

    return DateTime.now().isBefore(lockoutTime);
  }
}
