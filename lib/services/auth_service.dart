import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static FirebaseAuth? _authInstance;
  static bool _initialized = false;

  static bool get isFirebaseReady {
    if (_initialized) return true;
    try {
      Firebase.app();
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static FirebaseAuth? get _auth {
    if (!isFirebaseReady) return null;
    try {
      _authInstance ??= FirebaseAuth.instance;
      return _authInstance;
    } catch (e) {
      debugPrint('FirebaseAuth not available: $e');
      return null;
    }
  }

  static User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (e) {
      return null;
    }
  }

  static bool get isSignedIn {
    try {
      return _auth?.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  static Stream<User?> get onAuthStateChanged {
    try {
      return _auth?.authStateChanges() ?? const Stream.empty();
    } catch (e) {
      return const Stream.empty();
    }
  }

  /// Sign in with Google
  static Future<User?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception(
          'Firebase is not ready. Please refresh the page and try again.');
    }

    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    if (kIsWeb) {
      // Try popup first, fall back to redirect
      try {
        final UserCredential userCredential =
            await auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } catch (popupError) {
        debugPrint('Popup sign-in failed: $popupError, trying redirect...');
        // If popup blocked or failed, try redirect
        try {
          await auth.signInWithRedirect(googleProvider);
          // After redirect, the page reloads and user will be signed in
          // Check for redirect result
          final UserCredential result = await auth.getRedirectResult();
          return result.user;
        } catch (redirectError) {
          debugPrint('Redirect sign-in also failed: $redirectError');
          throw Exception(
              'Google Sign-In failed. Please allow popups for this site and try again.');
        }
      }
    } else {
      // Mobile
      final UserCredential userCredential =
          await auth.signInWithProvider(googleProvider);
      return userCredential.user;
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
