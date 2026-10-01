# Flutter Chrome QA

## Current focus

Develop the mobile-first Flutter app in **Chrome** with `flutter run -d chrome`. No Android Gradle setup or APK generation is part of this iteration.

## Verified redesigned version

- `flutter analyze`: clean.
- **36 Flutter tests passed** (16 repository/auth/persistence, 9 domain/matching, 11 widget journeys/layout tests).
- Actual Chromium browser checks passed: short swipe resets, complete swipe opens login without authenticating, explicit email sign-in, Home/mobile navigation, Find/list/details, seat reservation, confirmation, chat send, cancellation restoration, offer publication, driver request fulfilment and sign-out.
- Browser assertions observed the persisted demo records as well as visible Flutter controls.
- Browser runtime errors: **none** in the checked journey.
- Mobile screenshots are from the actual running Flutter Chrome app, not HTML/mockup artboards. See `screenshots/` and `CHROME_SMOKE_RESULTS.json`.
- Chrome release compilation succeeded with bundled local resources.

## Re-run locally

```bash
flutter pub get
flutter analyze
flutter test --concurrency=1
flutter run -d chrome
```

A fresh browser begins at welcome → swipe Get started → login. Use a new browser profile or clear this app's browser storage to repeat first-launch onboarding. Returning explicitly authenticated sessions persist.

## Preview environment

The standard `flutter run -d chrome` debug command was launched successfully here, but running its resident compiler plus multiple test browsers exceeded the small sandbox's memory budget. The shared preview therefore serves the **compiled Flutter app** in Chrome. It is the same Dart UI/state/repository code, not a separate HTML website. Local development on your computer should use `flutter run -d chrome` for hot reload.

To reproduce the resource-light preview:

```bash
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run -O2
python3 -m http.server 3000 --bind 0.0.0.0 --directory build/web
```

## Backend boundary

No production Firebase project is configured by default. Demo mode is local to the browser and no other person is online in its chat. The prior Firestore rules suite has 16 passing emulator cases; those rule files were retained unchanged. A real two-account, two-device Firebase acceptance test remains a project-configuration step.

No new APK, native-device test or native Figma file is claimed. The bulky HTML design exports and APK automation have been removed; only Flutter's minimal web bootstrap remains for Chrome support.
