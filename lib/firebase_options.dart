import 'package:firebase_core/firebase_core.dart';

abstract final class FirebaseEnvironment {
  static const _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBKgtPLXT9grC4Sxnk55mcBKk-yYtlzjp8',
  );
  static const _appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:1077225244994:web:a5b90b7ed770208a1aa0db',
  );
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '1077225244994',
  );
  static const projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'irfandevs77-d9520',
  );
  static const _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'irfandevs77-d9520.firebaseapp.com',
  );
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'irfandevs77-d9520.firebasestorage.app',
  );
  static const _measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: 'G-HLMM5HTE1E',
  );

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  static FirebaseOptions get webOptions => FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: projectId,
    authDomain: _authDomain.isEmpty ? null : _authDomain,
    storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
    measurementId: _measurementId.isEmpty ? null : _measurementId,
  );
}
