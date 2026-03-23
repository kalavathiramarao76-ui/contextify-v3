import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';

bool webIsFirebaseReady() {
  try {
    Firebase.app();
    return true;
  } catch (_) {
    return false;
  }
}

AppUser? _fbUserToAppUser(fb.User? user) {
  if (user == null) return null;
  return AppUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoURL: user.photoURL,
  );
}

AppUser? webGetCurrentUser() {
  try {
    return _fbUserToAppUser(fb.FirebaseAuth.instance.currentUser);
  } catch (_) {
    return null;
  }
}

bool webIsSignedIn() {
  try {
    return fb.FirebaseAuth.instance.currentUser != null;
  } catch (_) {
    return false;
  }
}

Future<AppUser?> webSignInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final fb.UserCredential userCredential =
        await fb.FirebaseAuth.instance.signInWithCredential(credential);
    return _fbUserToAppUser(userCredential.user);
  } catch (e) {
    rethrow;
  }
}

Future<void> webSignOut() async {
  try {
    await fb.FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  } catch (_) {}
}
