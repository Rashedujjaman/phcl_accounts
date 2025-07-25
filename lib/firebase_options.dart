// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA-dZG53qX13jL_DeiPym1DR7rLoEzoS34',
    appId: '1:842191352330:web:81d2e2cb41a657545125f3',
    messagingSenderId: '842191352330',
    projectId: 'phcl-accounts',
    authDomain: 'phcl-accounts.firebaseapp.com',
    storageBucket: 'phcl-accounts.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJVPAdQmfPwCoRhKS_xgKuPbu6vhCitSU',
    appId: '1:842191352330:android:1217270fa640653b5125f3',
    messagingSenderId: '842191352330',
    projectId: 'phcl-accounts',
    storageBucket: 'phcl-accounts.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBPO-H5nG3PBYeY9HJN2swEUVWNGAHr2ZQ',
    appId: '1:842191352330:ios:2a19906892098e885125f3',
    messagingSenderId: '842191352330',
    projectId: 'phcl-accounts',
    storageBucket: 'phcl-accounts.firebasestorage.app',
    iosBundleId: 'com.example.phclAccounts',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBPO-H5nG3PBYeY9HJN2swEUVWNGAHr2ZQ',
    appId: '1:842191352330:ios:2a19906892098e885125f3',
    messagingSenderId: '842191352330',
    projectId: 'phcl-accounts',
    storageBucket: 'phcl-accounts.firebasestorage.app',
    iosBundleId: 'com.example.phclAccounts',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA-dZG53qX13jL_DeiPym1DR7rLoEzoS34',
    appId: '1:842191352330:web:bf0de6a2b6d0bb315125f3',
    messagingSenderId: '842191352330',
    projectId: 'phcl-accounts',
    authDomain: 'phcl-accounts.firebaseapp.com',
    storageBucket: 'phcl-accounts.firebasestorage.app',
  );
}
