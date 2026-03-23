import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// Simple user model (no Firebase dependency)
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
    );
  }
}

@JS('signInWithGoogle')
external JSPromise<JSString> _jsSignInWithGoogle();

@JS('signOutFirebase')
external JSPromise<JSAny?> _jsSignOut();

@JS('getCurrentUser')
external JSString? _jsGetCurrentUser();

@JS('isFirebaseReady')
external JSBoolean? _jsIsFirebaseReady();

class AuthService {
  static AppUser? _cachedUser;

  /// Check if Firebase is initialized (JS side)
  static bool get isFirebaseReady {
    if (!kIsWeb) return false;
    try {
      final result = _jsIsFirebaseReady();
      return result?.toDart ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get current user from JS
  static AppUser? get currentUser {
    if (!kIsWeb) return _cachedUser;
    try {
      final userJson = _jsGetCurrentUser();
      if (userJson == null) {
        _cachedUser = null;
        return null;
      }
      final data = jsonDecode(userJson.toDart) as Map<String, dynamic>;
      _cachedUser = AppUser.fromJson(data);
      return _cachedUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return _cachedUser;
    }
  }

  /// Whether user is signed in
  static bool get isSignedIn {
    if (!kIsWeb) return _cachedUser != null;
    try {
      return _jsGetCurrentUser() != null;
    } catch (e) {
      return false;
    }
  }

  /// Sign in with Google via JS interop
  static Future<AppUser?> signInWithGoogle() async {
    if (!kIsWeb) {
      throw Exception('Google Sign-In is only available on web');
    }

    if (!isFirebaseReady) {
      throw Exception(
          'Firebase is not ready. Please refresh the page and try again.');
    }

    try {
      final resultJs = await _jsSignInWithGoogle().toDart;
      final resultStr = resultJs.toDart;
      final data = jsonDecode(resultStr) as Map<String, dynamic>;
      _cachedUser = AppUser.fromJson(data);
      return _cachedUser;
    } catch (e) {
      final errorStr = e.toString();
      debugPrint('Google Sign-In error: $errorStr');

      if (errorStr.contains('popup-closed-by-user')) {
        return null; // User cancelled - not an error
      }
      if (errorStr.contains('popup-blocked')) {
        throw Exception(
            'Popup was blocked. Please allow popups for this site.');
      }
      if (errorStr.contains('unauthorized-domain')) {
        throw Exception(
            'This domain is not authorized in Firebase. Please add it in Firebase Console.');
      }
      rethrow;
    }
  }

  /// Sign out via JS interop
  static Future<void> signOut() async {
    if (!kIsWeb) {
      _cachedUser = null;
      return;
    }
    try {
      await _jsSignOut().toDart;
      _cachedUser = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
      _cachedUser = null;
    }
  }
}
