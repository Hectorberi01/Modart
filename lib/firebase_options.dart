import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: dotenv.env['ANDROID_API_KEY'] ?? '',
          appId: dotenv.env['ANDROID_APP_ID'] ?? '',
          messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
          projectId: dotenv.env['PROJECT_ID'] ?? '',
          storageBucket: dotenv.env['STORAGE_BUCKET'] ?? '',
        );
      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: dotenv.env['IOS_API_KEY'] ?? '',
          appId: dotenv.env['IOS_APP_ID'] ?? '',
          messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
          projectId: dotenv.env['PROJECT_ID'] ?? '',
          storageBucket: dotenv.env['STORAGE_BUCKET'] ?? '',
          iosBundleId: dotenv.env['IOS_BUNDLE_ID'] ?? '',
        );
      default:
        return FirebaseOptions(
          apiKey: dotenv.env['ANDROID_API_KEY'] ?? '',
          appId: dotenv.env['ANDROID_APP_ID'] ?? '',
          messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
          projectId: dotenv.env['PROJECT_ID'] ?? '',
          storageBucket: dotenv.env['STORAGE_BUCKET'] ?? '',
        );
    }
  }
}
