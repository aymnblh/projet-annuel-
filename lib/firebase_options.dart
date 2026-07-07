import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCgy539QFdWYFOu_Ub90osZWzkN4mwCK7A',
    appId: '1:239683168280:web:73667aedb5f8cca3e17b6d',
    messagingSenderId: '239683168280',
    projectId: 'autoscout-cab49',
    authDomain: 'autoscout-cab49.firebaseapp.com',
    storageBucket: 'autoscout-cab49.firebasestorage.app',
    measurementId: 'G-0E9FTQZCQG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBD2ciX8b9iXxn3-BRKhjjaXXFUUv1f24U',
    appId: '1:239683168280:android:964fdc65ef8800e8e17b6d',
    messagingSenderId: '239683168280',
    projectId: 'autoscout-cab49',
    storageBucket: 'autoscout-cab49.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBRh7xRl20AwJ1puH_OtUjPs7mmGCgn3B4',
    appId: '1:239683168280:ios:b05175fe53d75a9ee17b6d',
    messagingSenderId: '239683168280',
    projectId: 'autoscout-cab49',
    storageBucket: 'autoscout-cab49.firebasestorage.app',
    iosBundleId: 'com.retec.bi3wechri',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBRh7xRl20AwJ1puH_OtUjPs7mmGCgn3B4',
    appId: '1:239683168280:ios:b05175fe53d75a9ee17b6d',
    messagingSenderId: '239683168280',
    projectId: 'autoscout-cab49',
    storageBucket: 'autoscout-cab49.firebasestorage.app',
    iosBundleId: 'com.retec.bi3wechri',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCgy539QFdWYFOu_Ub90osZWzkN4mwCK7A',
    appId: '1:239683168280:web:6a9647693cf69521e17b6d',
    messagingSenderId: '239683168280',
    projectId: 'autoscout-cab49',
    authDomain: 'autoscout-cab49.firebaseapp.com',
    storageBucket: 'autoscout-cab49.firebasestorage.app',
    measurementId: 'G-2P8FSLR6XG',
  );

}