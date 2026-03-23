import 'package:shared_preferences/shared_preferences.dart';

class UsageService {
  static const int maxFreeUses = 3;
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static int getTotalUses() => _prefs?.getInt('total_uses') ?? 0;

  static Future<void> incrementUse() async {
    final count = getTotalUses() + 1;
    await _prefs?.setInt('total_uses', count);
  }

  static bool needsSignIn(bool isSignedIn) {
    if (isSignedIn) return false; // signed in = unlimited
    return getTotalUses() >= maxFreeUses;
  }

  static int getRemainingFreeUses() {
    return (maxFreeUses - getTotalUses()).clamp(0, maxFreeUses);
  }
}
