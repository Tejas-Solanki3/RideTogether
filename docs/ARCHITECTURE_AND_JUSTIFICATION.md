# Architecture, matching and justification

## Objectives mapped to implementation

| Requirement | Implementation | Why |
|---|---|---|
| Logged-in student | Demo session adapter; Firebase Email/Password + verification | A runnable credential-free prototype, with a separate real auth path. Verified email is not advertised as an identity check. |
| Post offer/request | Immutable Dart `Ride`, `Form`, three steps, repository `postRide` | Typed records, validation close to input, clear progress, no accidental publication before review. |
| Find Ride | `ListView.separated` + `Card`, route/day/role filters | Familiar scanning of origin, destination, date, time and seats on every offer; requests honestly show needed seats. |
| Material 3 roles | Global seed theme, text/icon + filled/neutral driver/rider badge | Roles remain understandable without relying on colour alone. |
| Live list in Riverpod | Stream providers → `matchingRidesProvider` + immutable `RideFilters` | One source of truth; a Firestore snapshot updates cards, details, own posts and matches consistently. |
| Cloud Firestore storage | `FirestoreRideRepository`, rules and indexes | No Firebase-specific code in the UI; backend swap is a bootstrap override. |
| Seat decrement | Transaction spanning offer, match, and optionally request | Read current capacity; reserve all seats or fail; concurrent last-seat joins cannot both succeed. |
| My Matches, both sides | `participants` array-contains query; `isDriver(uid)` | One model supports driver/rider perspectives and private access. |
| Responsive journey | Mobile navigation capsule, centered app canvas in Chrome, scrollable cards/forms/dialogs | A single mobile-first layout keeps primary actions and guided progress accessible in Chrome. |
| Figma flow | Original kit was separated/removed; current iteration focuses on Flutter Chrome UI | No large embedded HTML design exports are bundled in the app repository. |

## Layers

```text
Material 3 UI / Form / ListView / Card
            ↓ reads / writes
Riverpod: session, live rides, live matches, filters, bookmarks, navigation
            ↓
RideRepository abstraction
   ├── DemoRideRepository: SharedPreferences + streams + mutation queue
   └── FirestoreRideRepository: Firebase Auth + snapshots + transactions
            ↓
Immutable domain objects + pure route/date matching
```

`main.dart` initializes one repository and injects it through `ProviderScope`. Session-dependent ride streams stop on sign-out / unverified state; signing back in creates a new authorized subscription rather than retaining a failed listener. A minute clock removes departed matches from Find Ride even if no database record changed.

## Matching policy

The primary filter accepts a ride only when:

1. It is active and not owned by the current student.
2. It has the selected role (offer/request).
3. Origin and destination IDs are **exact and ordered** matches.
4. Its **local departure date** equals the selected date and it has not departed.
5. Its remaining seats meet the selected minimum.
6. Optional free-only, saved-only and preferred-time filters pass. Time preference uses a ±60-minute window.

Results sort by departure, or contribution with departure as a tie-breaker. “Earliest on your route” is an explainable label, not an invented algorithmic confidence score.

**Why exact endpoints?** Similar text, opposite directions, nearby but inconvenient gates, or yesterday’s route can create misleading matches. Stable campus place IDs and directional equality prevent these false positives. **Why a time window?** Campus class schedules have predictable but flexible departure times. The optional one-hour window allows useful flexibility without hiding what time is actually offered. **Why capacity checks?** A valid route is not a usable ride if there is no seat.

A driver responding to a request must own an active offer with the same campus, directional route, same day, departure within 60 minutes and enough remaining seats for the **whole** request. A rider connecting their own request uses the same compatibility rule. Fuel contributions are suggested coordination amounts, not payment authorizations or binding fare quotes.

The custom SVG map is an **illustration**, not a geocoding, GPS, distance-calculation or navigation API. Campus locations and students are fictional examples.

## Reservation and cancellation invariants

```text
Connect:
  read current offer + deterministic match ID (+ request when applicable)
  reject own ride / past departure / incompatible request / insufficient seats
  if the match is already confirmed: return it, without a second decrement
  create confirmed match
  offer.availableSeats -= reservedSeats
  request → inactive, availableSeats 0, matchedId (if applicable)
  commit all changes atomically

Cancel before departure:
  authorize driver or rider
  if already cancelled: return without another increment
  match → cancelled
  offer.availableSeats += reservedSeats
  request → active, requestedSeats restored, matchedId cleared
  commit atomically
```

Firestore rules enforce these invariants with before/after document reads; this is not merely client-side validation. A cancelled match cannot be recreated on the same offer. Cancelling a connection does not delete its history or chat. Rides cannot be arbitrarily edited/deleted through these rules, which avoids invalidating existing reservations; editing/deleting posts is intentionally outside this prototype.

The offline adapter serializes mutations within **one app instance**, persists them, and rolls state back on a failed reservation save. It is not a distributed store and does not synchronize separate tabs/devices. The Firestore adapter is the multi-client path.

## Data model

- `rides/{rideId}`: owner snapshot, campus/endpoints, role, `departureAt`, `dateKey`, total/available seats, contribution, vehicle, note, active/matched flags, server creation/update timestamps and reservation mutation marker.
- `matches/{offerId_riderId}`: offer/request IDs, driver/rider IDs and display snapshots, participants array, route/date-time snapshot, reserved seats, contribution and status.
- `matches/{id}/messages/{messageId}`: sender ID, bounded text, server creation timestamp.

Public ride records contain a student display name and owner ID, not email addresses or phone numbers. Auth emails are used for account access, not shared in ride cards. Web/Android Firebase App IDs are supplied through public client configuration; no admin credentials belong in the client.

## Performance and production boundary

For this small-campus prototype, one campus-wide ride snapshot is filtered by Riverpod. For large datasets, push the route/day/kind constraints into Firestore queries, paginate results and update indexes to reduce read costs. Past records currently remain in the backend; retention and archival should be a real-campus policy.

Before launch, implement real campus membership claims/domain restrictions, moderation, abuse/rate limiting, account/data deletion, explicit timezone handling, retention rules, transport/insurance policy and appropriate privacy notices. No GPS tracking, payments, push notifications, ratings system or emergency support is implied by this prototype.
