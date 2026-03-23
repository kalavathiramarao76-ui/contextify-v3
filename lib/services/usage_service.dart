import 'package:shared_preferences/shared_preferences.dart';

enum UsageStatus {
  allowed,
  requiresSignIn,
  requiresDailyWait,
  requiresPro,
}

class UsageService {
  static const int maxFreeUses = 5; // Before sign-in required
  static const int maxDailyFreeUses = 2; // After sign-in, per day
  static const int maxTotalSignedInUses = 7; // Total free uses after sign-in before paywall

  // Storage keys
  static const String _totalUsesKey = 'total_uses';
  static const String _dailyUsesKey = 'daily_uses';
  static const String _dailyDateKey = 'daily_date';
  static const String _totalSignedInUsesKey = 'total_signed_in_uses';
  static const String _isProKey = 'is_pro';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
          'UsageService not initialized. Call UsageService.init() first.');
    }
    return _prefs!;
  }

  // --- Anonymous (not signed in) usage ---

  /// Get total anonymous uses
  static int getTotalUses() {
    return _instance.getInt(_totalUsesKey) ?? 0;
  }

  /// Increment anonymous uses
  static Future<void> _incrementTotalUses() async {
    final count = getTotalUses() + 1;
    await _instance.setInt(_totalUsesKey, count);
  }

  // --- Signed-in usage ---

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get daily uses for signed-in user (resets if date changed)
  static int getDailyUses() {
    final storedDate = _instance.getString(_dailyDateKey) ?? '';
    final today = _todayString();
    if (storedDate != today) {
      // Day has changed, reset daily counter
      _instance.setString(_dailyDateKey, today);
      _instance.setInt(_dailyUsesKey, 0);
      return 0;
    }
    return _instance.getInt(_dailyUsesKey) ?? 0;
  }

  /// Increment daily uses for signed-in user
  static Future<void> _incrementDailyUses() async {
    final today = _todayString();
    final storedDate = _instance.getString(_dailyDateKey) ?? '';
    if (storedDate != today) {
      await _instance.setString(_dailyDateKey, today);
      await _instance.setInt(_dailyUsesKey, 1);
    } else {
      final count = (_instance.getInt(_dailyUsesKey) ?? 0) + 1;
      await _instance.setInt(_dailyUsesKey, count);
    }
  }

  /// Get total signed-in uses (cumulative, never resets)
  static int getTotalSignedInUses() {
    return _instance.getInt(_totalSignedInUsesKey) ?? 0;
  }

  /// Increment total signed-in uses
  static Future<void> _incrementTotalSignedInUses() async {
    final count = getTotalSignedInUses() + 1;
    await _instance.setInt(_totalSignedInUsesKey, count);
  }

  // --- Pro status ---

  /// Check if user is pro
  static bool isPro() {
    return _instance.getBool(_isProKey) ?? false;
  }

  /// Set pro status (simulated purchase)
  static Future<void> setPro(bool value) async {
    await _instance.setBool(_isProKey, value);
  }

  // --- Main usage check ---

  /// Check if the user can perform an analysis
  static UsageStatus canUse(bool isSignedIn, bool isProUser) {
    // Pro users have unlimited access
    if (isProUser) return UsageStatus.allowed;

    // Not signed in: check anonymous limit
    if (!isSignedIn) {
      if (getTotalUses() >= maxFreeUses) {
        return UsageStatus.requiresSignIn;
      }
      return UsageStatus.allowed;
    }

    // Signed in but not pro
    // Check total signed-in uses for hard paywall
    if (getTotalSignedInUses() >= maxTotalSignedInUses) {
      return UsageStatus.requiresPro;
    }

    // Check daily limit
    if (getDailyUses() >= maxDailyFreeUses) {
      return UsageStatus.requiresDailyWait;
    }

    return UsageStatus.allowed;
  }

  /// Get remaining uses
  static int getRemainingUses(bool isSignedIn, bool isProUser) {
    if (isProUser) return -1; // Unlimited

    if (!isSignedIn) {
      return (maxFreeUses - getTotalUses()).clamp(0, maxFreeUses);
    }

    // Signed in: return min of daily remaining and total remaining
    final dailyRemaining =
        (maxDailyFreeUses - getDailyUses()).clamp(0, maxDailyFreeUses);
    final totalRemaining =
        (maxTotalSignedInUses - getTotalSignedInUses()).clamp(0, maxTotalSignedInUses);
    return dailyRemaining < totalRemaining ? dailyRemaining : totalRemaining;
  }

  /// Increment use based on auth state
  static Future<void> incrementUse(bool isSignedIn) async {
    if (!isSignedIn) {
      await _incrementTotalUses();
    } else {
      await _incrementDailyUses();
      await _incrementTotalSignedInUses();
    }
  }
}
