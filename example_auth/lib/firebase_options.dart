// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return web;
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDYSdpKuN9ix9AdvDJShRVvamACh7rrb2I',
    appId: '1:146734299654:web:2d11b705a8ee404f61e187',
    messagingSenderId: '146734299654',
    projectId: 'example-auth-1',
    authDomain: 'example-auth-1.firebaseapp.com',
    storageBucket: 'example-auth-1.appspot.com',
    measurementId: 'G-12KHSRDGE6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAjJZXLHO7PaO4r2k69NDZXs4jU1qJSuX4',
    appId: '1:146734299654:android:d5ec6e5fd75d66ef61e187',
    messagingSenderId: '146734299654',
    projectId: 'example-auth-1',
    storageBucket: 'example-auth-1.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDd1o8UIZ1KWSb5Pgu3cqL5R9i4aQb_uxs',
    appId: '1:146734299654:ios:3f323795df61490b61e187',
    messagingSenderId: '146734299654',
    projectId: 'example-auth-1',
    storageBucket: 'example-auth-1.appspot.com',
    iosClientId:
        '146734299654-gnc4uq31mi11ii8l1qe3a8p09f0gsf6a.apps.googleusercontent.com',
    iosBundleId: 'com.example.auth',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDd1o8UIZ1KWSb5Pgu3cqL5R9i4aQb_uxs',
    appId: '1:146734299654:ios:3f323795df61490b61e187',
    messagingSenderId: '146734299654',
    projectId: 'example-auth-1',
    storageBucket: 'example-auth-1.appspot.com',
    iosClientId:
        '146734299654-gnc4uq31mi11ii8l1qe3a8p09f0gsf6a.apps.googleusercontent.com',
    iosBundleId: 'com.example.auth',
  );
}
