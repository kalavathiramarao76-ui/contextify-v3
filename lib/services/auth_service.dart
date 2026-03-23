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
    return webIsFirebaseReady();
  }

  static AppUser? get currentUser {
    try {
      _cachedUser = webGetCurrentUser();
      return _cachedUser;
    } catch (e) {
      return _cachedUser;
    }
  }

  static bool get isSignedIn {
    try {
      return webIsSignedIn();
    } catch (e) {
      return false;
    }
  }

  static Future<AppUser?> signInWithGoogle() async {
    final user = await webSignInWithGoogle();
    _cachedUser = user;
    return user;
  }

  static Future<void> signOut() async {
    _cachedUser = null;
    await webSignOut();
  }
}
