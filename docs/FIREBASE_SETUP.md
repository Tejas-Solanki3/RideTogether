# Firebase setup

The app is fully usable locally by default. Firebase integration is implemented, but **no real Firebase project is configured in the supplied demo**.

## 1. Create and configure Firebase

1. Create your project in the Firebase console.
2. Register a **Web app** and an **Android app**. Android package ID: `com.ridetogether.ride_together` (check `android/app/build.gradle.kts`).
3. Enable **Authentication → Email/Password**.
4. Create a **Cloud Firestore** database. Choose a suitable region; apply the included rules, not open test-mode rules.
5. Add your deployed web host, localhost if needed, and your preview host under **Authentication → Settings → Authorized domains**. Use the hostname only, not `https://` or a port. In-app Arena previews use a proxy hostname, not the sandbox’s localhost.
6. Configure verification/password-reset email templates and their allowed action URLs in Firebase Auth.

## 2. Public client configuration

Copy and fill the relevant example:

```bash
cp config/firebase.web.example.json config/firebase.web.json
cp config/firebase.android.example.json config/firebase.android.json
```

Use **your Firebase app’s public client configuration** for the platform. In the Web SDK config, `apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain` and `storageBucket` map to the corresponding uppercase keys in the JSON example. Android’s App ID has `:android:` rather than `:web:`. Use its API key/project numbers from the Android app configuration / `google-services.json`.

Do **not** copy service-account JSON, private keys, OAuth client secrets, or Admin SDK credentials. The public Firebase API key is not a database password; authentication, security rules and App Check enforce access. The example files contain placeholders only. Filled config files are ignored by Git.

`Firebase.initializeApp(options: FirebaseConfig.options)` explicitly supplies the platform’s options, so this implementation does not require importing a generated `firebase_options.dart`. You may instead use FlutterFire CLI configuration, but then deliberately replace the bootstrap options with its generated `DefaultFirebaseOptions.currentPlatform`; do not leave two conflicting initialization strategies.

## 3. Deploy rules and indexes

Install Firebase CLI, log in, select your project and deploy:

```bash
npm install -g firebase-tools
firebase login
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes --project YOUR_PROJECT_ID
```

Or copy `.firebaserc.example` to `.firebaserc` and set your project ID. Indexes may take several minutes to become ready. The provided indexes cover:

- `rides`: `campusId == greenfield`, ordered by `departureAt`.
- `matches`: `participants array-contains UID`, ordered by `departureAt`.
- Chat uses the built-in single-field `createdAt` index.

## 4. Run Firebase mode

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=config/firebase.web.json
flutter run -d YOUR_ANDROID_DEVICE_ID --dart-define-from-file=config/firebase.android.json
```

Firebase mode starts at the login screen and does **not** copy fictional demo data into your database. Create two accounts with valid emails, verify both inboxes, and click **I’ve verified my email** to reload the user and refresh the ID token. A rider/driver can then post and connect from separate browsers/devices.

For Android, install the SDK and a compatible JDK (JDK 21 is a suitable choice for the generated Gradle 9.3.1 project). Run `flutter doctor`, accept SDK licenses, and let Flutter regenerate `android/local.properties` for your machine. The release manifest already includes Internet permission. No Firebase Admin SDK is involved. The generated Android release block still uses debug signing for the prototype; configure your own release keystore/signing before store distribution.

## 5. Real campus membership — important

The supplied rules require a **verified email**, but a verified email alone does **not** prove student status. The demo’s university is fictional. Before a real launch, update `member()` in `firestore.rules` to enforce your university domain, or use an administrator-issued campus membership claim. For example:

```text
function member() {
  return request.auth != null
    && request.auth.token.email_verified == true
    && request.auth.token.email.matches('.*@YOUR_UNIVERSITY_DOMAIN[.]edu');
}
```

Replace the expression with your actual institution domain. For multiple domains / campus affiliations, a server-issued membership claim is preferable. Do not let client code grant its own verified-student claim.

Update `CampusPlace.all`, displayed campus copy, and `campusId` in the model, repository query and rules together. The app currently displays dates/times in the device’s local timezone; Greenfield sample use assumes a single campus timezone. For real cross-timezone access, store an explicit IANA campus timezone and derive the campus `dateKey` consistently.

## Security and transaction behaviour

- Only signed-in verified members read campus ride posts.
- Ride creation validates owner, route, future departure, capacity, contribution, field lengths and schema.
- Seat changes are allowed **only alongside** a valid new match or cancellation in the same atomic transaction, checked with `getAfter()`.
- The deterministic match ID `offerId_riderId` prevents duplicate reservations. A confirmed duplicate is returned by the repository; a cancelled connection cannot be reopened on the same offer.
- Request fulfilment reserves all requested seats and closes the request. Either legitimate participant can connect it; third parties cannot.
- Only participants list/read existing match documents and their chat. Verified clients can check an absent match ID to support transaction existence reads; this grants no access to an existing stranger’s match.
- Cancellation changes only status/timestamp, restores seats and reopens a connected request exactly once, before departure.
- Messages are participant-owned, length-limited, immutable and server-timestamped. Cancelled chat is read-only.

Firestore transactions need a network connection; the app does not claim an offline reservation is confirmed. SDK snapshot caching is not a substitute for a successful transaction.

## Emulator tests

Requires Node 20+ and Java 21+:

```bash
cd firebase_tests
npm ci
npm run emulator
```

This starts a temporary Firestore Emulator, runs the security tests against the included rules, and shuts it down. No Firebase project or cloud credentials are used. Expected denial tests produce `PERMISSION_DENIED` log lines; they are successful tests, not test failures.

## Web deployment

```bash
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run -O2 \
  --dart-define-from-file=config/firebase.web.json
firebase deploy --only hosting --project YOUR_PROJECT_ID
```

Without the define file, that build remains a **local demo**, even if hosted on Firebase Hosting. Review public-domain settings, quota/billing limits, App Check, moderation/rate limits and transportation policy before making the service available to students.
