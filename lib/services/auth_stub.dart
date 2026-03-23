import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mobile auth: Simple local sign-in state (no Firebase/Google dependency)
// For real Google auth, replace with Firebase after registering Android app in Firebase Console

bool webIsFirebaseReady() => true;

AppUser? webGetCurrentUser() {
  // Check cached state
  return _MobileAuthState.currentUser;
}

bool webIsSignedIn() {
  return _MobileAuthState.isSignedIn;
}

Future<AppUser?> webSignInWithGoogle() async {
  // On mobile without Firebase configured, simulate sign-in
  // This allows users past the 3-free gate without real OAuth
  // TODO: Replace with real Firebase Google Sign-In after registering Android app
  final user = AppUser(
    uid: 'mobile-user-${DateTime.now().millisecondsSinceEpoch}',
    email: 'user@contextify.app',
    displayName: 'Contextify User',
    photoURL: null,
  );

  await _MobileAuthState.setSignedIn(user);
  return user;
}

Future<void> webSignOut() async {
  await _MobileAuthState.clear();
}

// Simple persistence for mobile auth state
class _MobileAuthState {
  static AppUser? _user;
  static bool _loaded = false;

  static bool get isSignedIn => _user != null;
  static AppUser? get currentUser => _user;

  static Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('auth_uid');
      final name = prefs.getString('auth_name');
      final email = prefs.getString('auth_email');
      if (uid != null) {
        _user = AppUser(uid: uid, displayName: name, email: email);
      }
    } catch (_) {}
  }

  static Future<void> setSignedIn(AppUser user) async {
    _user = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_uid', user.uid);
      if (user.displayName != null) await prefs.setString('auth_name', user.displayName!);
      if (user.email != null) await prefs.setString('auth_email', user.email!);
    } catch (_) {}
  }

  static Future<void> clear() async {
    _user = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_uid');
      await prefs.remove('auth_name');
      await prefs.remove('auth_email');
    } catch (_) {}
  }

  // Initialize on first access
  static Future<void> init() async => _load();
}
