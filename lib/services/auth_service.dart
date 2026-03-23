import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static FirebaseAuth? _authInstance;

  static FirebaseAuth? get _auth {
    try {
      _authInstance ??= FirebaseAuth.instance;
      return _authInstance;
    } catch (e) {
      debugPrint('FirebaseAuth not available: $e');
      return null;
    }
  }

  /// Current Firebase user (null if not signed in or Firebase unavailable)
  static User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (e) {
      debugPrint('Error getting currentUser: $e');
      return null;
    }
  }

  /// Whether the user is signed in (false if Firebase crashes)
  static bool get isSignedIn {
    try {
      return _auth?.currentUser != null;
    } catch (e) {
      debugPrint('Error checking isSignedIn: $e');
      return false;
    }
  }

  /// Stream of auth state changes
  static Stream<User?> get onAuthStateChanged {
    try {
      return _auth?.authStateChanges() ?? const Stream.empty();
    } catch (e) {
      debugPrint('Error getting auth state stream: $e');
      return const Stream.empty();
    }
  }

  /// Sign in with Google — uses popup on web, credential on mobile
  static Future<User?> signInWithGoogle() async {
    try {
      final auth = _auth;
      if (auth == null) {
        debugPrint('Firebase Auth not available for sign-in');
        return null;
      }

      if (kIsWeb) {
        // Web: Use signInWithPopup (google_sign_in package doesn't work on web)
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final UserCredential userCredential =
            await auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } else {
        // Mobile: Use signInWithProvider
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final UserCredential userCredential =
            await auth.signInWithProvider(googleProvider);
        return userCredential.user;
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
