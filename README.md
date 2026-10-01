# RideTogether
### Your campus, connected.

A real **Flutter** campus carpool application with a premium, Uber-inspired visual direction: warm-white surfaces, ink-black actions, restrained green accents, bundled Manrope typography, campus photography, and custom SVG artwork. The branding and layout are original, not an Uber clone.

**Created from scratch with:**
```bash
flutter create --platforms=android,web --org com.ridetogether --project-name ride_together ride_together
```

## Run the working demo

Use current Flutter stable. This project was built and checked with **Flutter 3.47.5 / Dart 3.13.4**. The Dart constraint is 3.10+; using the tested Flutter version or newer is recommended.

```bash
git clone https://github.com/Tejas-Solanki3/RideTogether.git
cd RideTogether
flutter pub get
flutter run -d chrome
```

If using the downloadable project archive instead, enter its `ride_together` folder and run the last two commands.

Android, with an emulator or phone connected:
```bash
flutter devices
flutter run -d YOUR_ANDROID_DEVICE_ID
```

No Firebase project or API key is needed for demo mode. It opens signed in as **Ishaan Mehta**, a sample student at the fictional **Greenfield University**. The app uses `shared_preferences` to persist demo rides, matches, chat and bookmarks on the current device/browser. This is not real authentication or a multi-device backend. Sign out to explore demo sign-in; no demo passwords are stored.

## What works

- **Post Ride** — offer/request role choice, Route → Details → Review progress, validated `Form`, date/time pickers, 1–6 seats, contribution, vehicle and pickup note.
- **Find Ride** — live Riverpod-managed `ListView` of `Card`s, directional route/day matching, time preference, minimum seats, free-only filtering, bookmarks, sorting and empty/error states. Every offer card shows origin, destination, date, time and available seats; request cards show seats needed instead of claiming to offer seats.
- **Connect** — a rider reserves one seat directly, or fulfils their own multi-seat request; a driver fulfils a request using their own compatible offer. The confirmation states exactly how many seats were reserved.
- **My Matches** — upcoming/past/cancelled connections on both driver and rider sides, live availability in your posts, details and chat. Cancelling before departure restores seats exactly once and reopens a matched request.
- **Chat** — persistent pickup coordination, quick messages, private participant-only Firestore access, and read-only cancelled conversations. Demo chat explicitly says no other person is online.
- **Responsive UI** — mobile bottom navigation, desktop sidebar, landscape-aware content and scrollable forms. All photos, fonts and SVGs are bundled.
- **Firebase mode** — Email/Password auth + email verification, Cloud Firestore snapshots, transaction-based reservations/cancellations, validated security rules and the required indexes.

## Try the journey

1. On **Find Ride**, open Aarav’s ride and connect. Available seats drop from 3 to 2; the connection appears as a rider in **My Matches**.
2. Open chat, send a pickup message, reload: your data remains.
3. In **My Matches → Details**, cancel before departure: the seat returns to the offer.
4. Post your own offer. After publishing, choose **Find compatible requests**. Open a request, select one of your compatible offers and offer a lift.
5. Post a request for two seats. **Find compatible rides** preselects your request in the offer detail screen; connecting reserves both seats and marks your request matched.
6. For a fresh start, open **Your profile → Reset local demo**. If you return after the sample departure date, reset the demo or select a new date/post a new ride.

## Connect your Firebase project

The default app does **not** connect to a production Firebase project. See [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md) for public client configuration, email auth, authorized domains, rules/index deployment and Android setup. Never place an Admin SDK service account or private key in this app.

```bash
flutter run -d chrome --dart-define-from-file=config/firebase.web.json
```

## Figma-ready design deliverable

`design/` contains **19 editable SVG screen artboards, a guided flow map, design tokens, an offline clickable design preview, and a local Figma plugin** that generates native text/vector/image layers and prototype links. Start with [design/README.md](design/README.md) or open `design/prototype.html`.

There is no fabricated `.fig` file or claim that a Figma file was created in your account. Run the local plugin to save an actual Figma design under your own account. Its logic was exercised locally using API mocks; execution inside your Figma editor remains a handoff step.

## Project structure

```text
lib/
  main.dart                    Bootstrap, demo/Firebase selection, ProviderScope
  config/firebase_config.dart  Public client configuration via Dart defines
  domain/models.dart           Student, Ride, RideMatch, ChatMessage, filters
  domain/matching.dart         Pure matching logic and posting validation
  data/                        Repository interface, offline demo, Firestore
  state/providers.dart         Live streams, matching state, filters, navigation
  ui/                          Material 3 theme, responsive shell, screens/widgets
assets/                        Bundled photos, portraits, font and SVGs
android/                       Android project generated by flutter create
web/                           Web shell, branding and manifest
firestore.rules                Enforced atomic reservation / participant access
firestore.indexes.json         Campus rides and participant matches indexes
firebase_tests/                Firestore Emulator security tests
test/                          Model, logic, repository and widget tests
design/                        Figma import, artboards, tokens and guided prototype
docs/                          Setup, architecture, justification and QA results
```

## Checks and build

```bash
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run -O2

# Serve the compiled web app locally; do not open index.html as file://.
python3 -m http.server 3000 --bind 0.0.0.0 --directory build/web

# Android APK, after installing Android SDK + a compatible JDK:
flutter build apk --release
```

For this handoff: **31 Flutter tests passed; 16 Firestore Emulator tests passed; compiled-web end-to-end checks passed.** Mobile layouts were checked at 360, 390, 768, 1024 and 1440 px. The Android source is included, but an Android APK/device build was **not** produced or tested in this workspace. No live Firebase project was configured. See [docs/QA.md](docs/QA.md).

This is a campus coordination prototype, not a taxi, payment, GPS-navigation, emergency, or identity-verification service. For real deployment, enforce campus membership, add moderation/rate limits, choose an explicit campus timezone, and review campus transportation/privacy policies.
