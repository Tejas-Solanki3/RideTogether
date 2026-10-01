import 'package:firebase_core/firebase_core.dart';

/// Public client configuration, not admin credentials. Use --dart-define-from-file.
/// Leave USE_FIREBASE unset to run the fully offline campus demo.
class FirebaseConfig {
  static const enabled = bool.fromEnvironment(
    'USE_FIREBASE',
    defaultValue: false,
  );
  static FirebaseOptions get options {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if ([apiKey, appId, senderId, projectId].any((v) => v.isEmpty)) {
      throw StateError(
        'Missing Firebase configuration. Follow docs/FIREBASE_SETUP.md, or run without USE_FIREBASE for the demo.',
      );
    }
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    );
  }
}
