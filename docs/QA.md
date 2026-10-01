# QA and handoff status

## Verified in this workspace

- Flutter project generated using `flutter create` for **Android and Web**.
- Static analysis: `flutter analyze` — no issues after final fixes.
- **31 Flutter tests**: model/JSON mapping, directional route/date/time matching, filters/sort, duplicate joins, last-seat behaviour, cancellation, driver request fulfilment, rider multi-seat fulfilment, persistence, chat, live streams and posting validation.
- Widget layouts checked at **360, 390, 768, 1024 and 1440 px** with the bundled font.
- Widget journeys: offer post → review → publish; find → reserve → confirm → My Matches; mobile two-seat request → matching offer → reservation.
- **16 Firestore Emulator tests**: ownership/schema validation, verified auth boundary, atomic reservations, duplicate/last-seat races, private matches/chat, immutable messages, cancellation/reopening, driver/rider fulfilment and missing-match transaction reads.
- Release web build: `flutter build web --release --no-web-resources-cdn --no-wasm-dry-run -O2`.
- Actual compiled Flutter browser checks: desktop load, guided posting, driver request fulfilment, rider joining, chat send/persistence, cancellation, reload persistence, reverse-route exclusion and 390px mobile navigation. See `WEB_SMOKE_RESULTS.json`.
- Design HTML: embedded assets and guided click links checked. SVG artboards parse as XML. Local Figma plugin JavaScript syntax and construction/link logic exercised using an API mock: **20 frames including the flow map, with 221 prototype links**. This is not equivalent to running the plugin in Figma.

## Intentionally not claimed

- No APK, Android emulator/device or iOS build was tested. Android project source is supplied; the selected target was Android + Web.
- No production Firebase project, cloud credentials or multi-device production deployment was connected. The included Firebase adapter and security rules require your project setup.
- No native Figma file was saved in your account. The import plugin/SVGs are the design handoff; import and save the actual Figma file yourself.
- No real drivers, student identities, GPS map/navigation, payment collection, push notifications or emergency services exist in the sample demo.

## Re-run checks

```bash
flutter pub get
flutter analyze
flutter test
```

Firestore rules (Node 20+, Java 21+):
```bash
cd firebase_tests
npm ci
npm run emulator
```

Compiled web (two terminals):
```bash
# Terminal 1
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run -O2
python3 -m http.server 3000 --bind 0.0.0.0 --directory build/web

# Terminal 2
cd tools/browser
npm install
npx playwright install --with-deps chromium
npm test
```

Set `TEST_URL` if serving the web build on a different host/port. The smoke test creates fresh, isolated browser sessions and writes screenshots under `docs/screenshots/`. It does not modify your normal demo browser data or connect to Firebase.

## Manual two-device Firebase acceptance check

1. Configure Firebase, deploy rules/indexes, create and verify two accounts.
2. Account A posts an offer with one remaining seat.
3. Account B sees and joins it; Account A sees zero available seats without a refresh.
4. Send chat from either side; confirm the other sees it live.
5. Cancel before departure; both should see the seat return.
6. Repeat using a two-seat request and a compatible driver offer.
7. Try a third account on the last seat; confirm only one reservation succeeds.

This final acceptance check requires your actual Firebase project and has not been represented as completed here.
