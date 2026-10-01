# RideTogether

A real **Flutter / Dart** campus carpool app with a mobile-first **black-and-white** interface, bundled Manrope typography and Lucide SVG icons.

## Current development target: Chrome

```bash
git clone https://github.com/Tejas-Solanki3/RideTogether.git
cd RideTogether
flutter pub get
flutter run -d chrome
```

Use Flutter stable (tested with Flutter 3.47.5 / Dart 3.13.4). The current focus is developing and previewing the Flutter UI in Chrome. **No Android SDK, Gradle setup or APK generation is needed for this workflow.** Android project source is retained for future use.

In a headless workspace, the Chrome driver can launch with `CHROME_EXECUTABLE` and headless flags. For a browser-accessible Flutter dev server without launching a local browser, use:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 \
  --no-web-resources-cdn
```

## First launch

**Welcome → slide Get started to the right → login → Home.**

The slider is a real horizontal drag control, with an equivalent screen-reader action. It opens login; it does not authenticate. Sign in/create an account, or explicitly choose **Try the campus demo**. Fresh installations do not automatically enter as a sample student. Returning sessions persist only after explicit sign-in.

## App screens

- **Home:** greeting, destination selection, rider/driver intent, pickup/drop-off, date and passenger count.
- **Find:** same route/day, live capacity, offer/request roles, saved rides, filters and sorting.
- **Post:** Route → Details → Review, required vehicle for drivers, 1–6 seats, suggested fuel contribution and pickup notes.
- **Rides:** upcoming/past/cancelled driver and rider connections, your posts, details and chat.
- **Profile:** account, campus/safety/data information, reset local demo and sign-out.

The design uses mobile composition inspired by the supplied reference, not a separate HTML website: monochrome photo/avatars, consistent outline icons, calm rounded surfaces, black primary actions and a floating navigation capsule.

## Demo and Firebase

The default local demo runs without credentials. Demo rides/matches/chat are stored in this browser or device using SharedPreferences. No demo password is stored; this is not real authentication or multi-device chat. The sample campus and student names are fictional.

Firebase mode is implemented separately using Email/Password + email verification, Cloud Firestore live snapshots, atomic multi-seat reservation/cancellation and participant-private chat. Fill your **public client config** using `config/firebase.web.example.json` for Chrome. Never place service-account keys or Admin SDK credentials in the client.

```bash
flutter run -d chrome --dart-define-from-file=config/firebase.web.json
```

Verified email alone does not verify student status; enforce your actual campus domain or administrator-issued membership claims before a real launch. The map is illustrative, and the app does not collect payments or provide GPS navigation.

## Why GitHub previously showed mostly HTML

The old repo included about **3.4 MB of embedded HTML design exports versus 283 KB of Dart**. Those exports, their generator, and the desktop/web-style UI have been removed. This project retains only the tiny Flutter web entrypoint required to run Dart in Chrome—**not** the bulky HTML design prototypes. Build output/dependencies are ignored.

Small JavaScript files under `firebase_tests/` test backend security rules; they are not website UI. All app screens, state and matching logic are Dart.

## Checks

```bash
flutter analyze
flutter test --concurrency=1
```

The redesigned app has **36 passing Flutter tests** covering matching, persistence, explicit authentication, swipe behaviour, layout widths 360/390/430/768, guided posting, multi-seat reservations, chat and cancellation.

Firestore security tests (Node 20+, Java 21+, independent of Chrome UI development):

```bash
cd firebase_tests
npm ci
npm run emulator
```

## Structure

```text
lib/domain/      Immutable Dart models and pure matching policy
lib/data/        Offline demo and Firestore adapters
lib/state/       Riverpod live state, filters, session and onboarding
lib/ui/          Flutter screens, mobile navigation, theme and components
assets/          Bundled photos, SVG icons, font and licenses
web/             Minimal generated Flutter Chrome runtime entrypoint
android/         Retained native project source; no APK workflow
firebase_tests/ Firestore Emulator security tests
```

The project originally started from `flutter create`, not an HTML imitation. There is no fabricated Figma file or separate HTML prototype in the app source.
