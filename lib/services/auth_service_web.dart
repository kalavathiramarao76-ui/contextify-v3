import 'dart:convert';
import 'dart:js_interop';
import 'auth_service.dart';

@JS('signInWithGoogle')
external JSPromise<JSString> _jsSignInWithGoogle();

@JS('signOutFirebase')
external JSPromise<JSAny?> _jsSignOut();

@JS('getCurrentUser')
external JSString? _jsGetCurrentUser();

@JS('isFirebaseReady')
external JSBoolean? _jsIsFirebaseReady();

bool webIsFirebaseReady() {
  try {
    final result = _jsIsFirebaseReady();
    return result?.toDart ?? false;
  } catch (e) {
    return false;
  }
}

AppUser? webGetCurrentUser() {
  try {
    final userJson = _jsGetCurrentUser();
    if (userJson == null) return null;
    final data = jsonDecode(userJson.toDart) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  } catch (e) {
    return null;
  }
}

bool webIsSignedIn() {
  try {
    return _jsGetCurrentUser() != null;
  } catch (e) {
    return false;
  }
}

Future<AppUser?> webSignInWithGoogle() async {
  if (!webIsFirebaseReady()) {
    throw Exception('Firebase is not ready. Please refresh the page and try again.');
  }
  try {
    final resultJs = await _jsSignInWithGoogle().toDart;
    final resultStr = resultJs.toDart;
    final data = jsonDecode(resultStr) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  } catch (e) {
    final errorStr = e.toString();
    if (errorStr.contains('popup-closed-by-user')) return null;
    if (errorStr.contains('popup-blocked')) {
      throw Exception('Popup was blocked. Please allow popups for this site.');
    }
    rethrow;
  }
}

Future<void> webSignOut() async {
  try {
    await _jsSignOut().toDart;
  } catch (e) {
    // ignore
  }
}
