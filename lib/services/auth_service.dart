import 'package:flutter/foundation.dart';
import 'auth_stub.dart'
    if (dart.library.js_interop) 'auth_service_web.dart';

/// Simple user model
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

class AuthService {
  static AppUser? _cachedUser;

  static bool get isFirebaseReady {
    if (!kIsWeb) return false;
    return webIsFirebaseReady();
  }

  static AppUser? get currentUser {
    if (!kIsWeb) return _cachedUser;
    try {
      _cachedUser = webGetCurrentUser();
      return _cachedUser;
    } catch (e) {
      return _cachedUser;
    }
  }

  static bool get isSignedIn {
    if (!kIsWeb) return _cachedUser != null;
    try {
      return webIsSignedIn();
    } catch (e) {
      return false;
    }
  }

  static Future<AppUser?> signInWithGoogle() async {
    if (!kIsWeb) {
      throw Exception('Google Sign-In is only available on web');
    }
    final user = await webSignInWithGoogle();
    _cachedUser = user;
    return user;
  }

  static Future<void> signOut() async {
    _cachedUser = null;
    if (!kIsWeb) return;
    await webSignOut();
  }
}
