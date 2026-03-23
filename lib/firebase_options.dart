import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA8_NLsIU-daIZpNmuuAHGDI0ihDrBDqnM',
    authDomain: 'app1-99b5a.firebaseapp.com',
    projectId: 'app1-99b5a',
    storageBucket: 'app1-99b5a.firebasestorage.app',
    messagingSenderId: '967175964103',
    appId: '1:967175964103:web:9aa30081b8538660c6c5e2',
  );

  static FirebaseOptions get currentPlatform => web;
}
