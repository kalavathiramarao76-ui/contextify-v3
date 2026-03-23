import 'auth_service.dart';

bool webIsFirebaseReady() => false;
AppUser? webGetCurrentUser() => null;
bool webIsSignedIn() => false;
Future<AppUser?> webSignInWithGoogle() async =>
    throw Exception('Google Sign-In is only available on web');
Future<void> webSignOut() async {}
