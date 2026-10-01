# Firebase setup / Flutter Chrome

The app runs locally in Chrome without Firebase credentials by default. The optional production adapter uses Firebase Auth and Cloud Firestore; no cloud project is configured in the sample.

## Configure Chrome mode

1. Create your Firebase project and register a **Web app** (Firebase's client registration for Flutter Chrome).
2. Enable Authentication → Email/Password.
3. Create a Cloud Firestore database.
4. Copy `config/firebase.web.example.json` to `config/firebase.web.json` and fill your public client config.
5. Add `localhost` and your preview/deployment hostname to Firebase Auth authorized domains if required.
6. Deploy the provided rules/indexes.

```bash
npm install -g firebase-tools
firebase login
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes --project YOUR_PROJECT_ID

flutter run -d chrome --dart-define-from-file=config/firebase.web.json
```

This client registration does not create a separate HTML website. All app screens and logic remain Dart/Flutter.

## Public configuration only

Map Firebase's `apiKey`, `appId` (with `:web:`), `messagingSenderId`, `projectId`, `authDomain` and `storageBucket` to the uppercase keys in the JSON example. The app explicitly supplies `FirebaseConfig.options` to `Firebase.initializeApp`.

Do not add a service-account JSON, Admin SDK private key, OAuth client secret or signing key. Filled config files are ignored by Git. Public client configuration is not a database password; Auth and security rules enforce access.

The retained `firebase.android.example.json` is for future native testing, not the current development focus. Web and Android App IDs are different.

## Authentication and data

Welcome swipe → login/registration → verify email → Home. Firebase mode does not copy sample students into the database. Register two real test accounts with valid inboxes and verify them before posting/joining.

Campus rides use stable endpoint IDs and a campus/departure query. Matches use participant-array access. Join/fulfil/cancel are atomic transactions across offer, match and linked request; rules enforce seat capacity, ownership and privacy. A deterministic offer/rider match ID prevents duplicate decrements. Cancelled chat is read-only.

Firestore reservations require a network connection. Cached snapshots are not an offline reservation confirmation.

## Real campus admission

A verified email is not proof of student status. Before real deployment, restrict `member()` to your actual university domains or use administrator-issued membership claims. Clients must not grant their own claims.

Choose an explicit campus timezone for cross-timezone access. Add moderation, retention/account deletion and campus transportation/privacy policy before launch. The map is illustrative and no payments are collected.

## Security tests, independent of Chrome UI

Node 20+ and Java 21+:

```bash
cd firebase_tests
npm ci
npm run emulator
```

This temporary Firestore Emulator uses no cloud credentials. Expected denial cases produce `PERMISSION_DENIED` log lines. The current UI development workflow needs neither this emulator nor Android SDK/APK generation.
