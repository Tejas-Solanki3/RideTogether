# Mobile-first Flutter redesign

## Current target

Develop and preview the **Flutter app in Chrome using `flutter run -d chrome`**. No APK generation or Android Gradle work is part of the current scope. Android source remains available for later native testing.

## Design

The supplied reference informs mobile composition: greeting, destination search, paired route/date/passenger tiles, activity cards and a floating navigation capsule. Blue accents, taxi/bus/bike choices, wallet balances and payment flows are not invented for this campus carpool.

The palette is black, white and neutral grey. Manrope provides a refined type hierarchy without proprietary Uber fonts. Bundled Lucide SVGs give one consistent icon family. Photography and avatars are now color; primary actions are black with white text/icons. Containers use restrained 16–24 px corner radii and accessible touch targets.

## Entry flow

The user selected a **swipe-to-start bar**, not an intro carousel. First launch displays a welcome screen. A completed swipe saves onboarding completion and opens login. It never signs a user in.

Demo entry is explicit. Previous automatic v1 demo sessions are invalidated without deleting stored rides; returning v2 sessions persist only after explicit login.

## App, not website

Home / Post / Rides / You navigation remains mobile-first in Chrome. Wide browser windows show a centered app-width canvas rather than a desktop dashboard. Details and chat use Flutter routes. Forms, pickers, cards and live state are Flutter widgets.

The repository removes the large self-contained HTML design exports and generator. `web/index.html` is only the small Flutter bootstrap required by the Chrome development target. This is real removal of unnecessary HTML, not a language-statistics override.

## Logic retained

Immutable Dart Ride models, Riverpod streams, Firestore/demo adapters, exact route/day matching, group seat reservations, cancellation restoration and private chat are retained. The current 43-test Flutter suite includes regression coverage for narrow onboarding windows and saved demo-avatar migration.
