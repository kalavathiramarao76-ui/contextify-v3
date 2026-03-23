import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static FirebaseAuth? _authInstance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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

  /// Sign in with Google
  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final auth = _auth;
      if (auth == null) {
        debugPrint('Firebase Auth not available for sign-in');
        return null;
      }

      final userCredential = await auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  /// Sign out from both Firebase and Google
  static Future<void> signOut() async {
    try {
      await Future.wait([
        if (_auth != null) _auth!.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
