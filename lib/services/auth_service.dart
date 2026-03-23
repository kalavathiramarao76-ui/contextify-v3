import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      return null;
    }
  }

  static bool get isSignedIn {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  static Stream<User?> get onAuthStateChanged {
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (e) {
      return const Stream.empty();
    }
  }

  /// Sign in with Google
  static Future<User?> signInWithGoogle() async {
    final FirebaseAuth auth;
    try {
      auth = FirebaseAuth.instance;
    } catch (e) {
      throw Exception(
          'Firebase is not ready. Please refresh the page and try again.');
    }

    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    if (kIsWeb) {
      try {
        final UserCredential userCredential =
            await auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } catch (popupError) {
        debugPrint('Popup failed: $popupError, trying redirect...');
        try {
          await auth.signInWithRedirect(googleProvider);
          final UserCredential result = await auth.getRedirectResult();
          return result.user;
        } catch (redirectError) {
          debugPrint('Redirect also failed: $redirectError');
          rethrow;
        }
      }
    } else {
      final UserCredential userCredential =
          await auth.signInWithProvider(googleProvider);
      return userCredential.user;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
