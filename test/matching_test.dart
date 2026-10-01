import 'package:flutter_test/flutter_test.dart';
import 'package:ride_together/domain/models.dart';
import 'package:ride_together/domain/matching.dart';

void main() {
  final now = DateTime(2030, 10, 1, 9);
  final day = DateTime(2030, 10, 1);
  Ride make({
    String id = 'r',
    String owner = 'driver',
    String origin = 'north_gate',
    String destination = 'riverside_metro',
    int hour = 17,
    int minute = 30,
    int date = 1,
    int seats = 3,
    int price = 40,
    RideKind kind = RideKind.offer,
  }) => Ride(
    id: id,
    ownerId: owner,
    ownerName: 'Driver Student',
    ownerAvatar: 'aarav',
    originId: origin,
    destinationId: destination,
    kind: kind,
    departureAt: DateTime(2030, 10, date, hour, minute),
    createdAt: now,
    totalSeats: seats,
    availableSeats: seats,
    contribution: price,
    vehicle: 'Honda City',
  );
  final filters = RideFilters(
    originId: 'north_gate',
    destinationId: 'riverside_metro',
    date: day,
  );
  test('ride round-trips JSON and preserves seat capacity on copy', () {
    final r = make();
    final copy = Ride.fromJson(r.toJson()).copyWith(availableSeats: 2);
    expect(copy.totalSeats, 3);
    expect(copy.availableSeats, 2);
    expect(copy.dateKey, '2030-10-01');
    expect(copy.origin.name, 'North Gate');
    expect(copy.ownerId, r.ownerId);
  });
  test(
    'exact directional route: reversed and other destinations do not match',
    () {
      final matches = matchingRides(
        [
          make(),
          make(
            id: 'reverse',
            origin: 'riverside_metro',
            destination: 'north_gate',
          ),
          make(id: 'library', destination: 'central_library'),
        ],
        filters,
        'me',
        now: now,
      );
      expect(matches.map((r) => r.id), ['r']);
    },
  );
  test('matches same day only; excludes departed rides', () {
    final matches = matchingRides(
      [make(), make(id: 'tomorrow', date: 2), make(id: 'past', hour: 8)],
      filters,
      'me',
      now: now,
    );
    expect(matches.length, 1);
  });
  test('own rides, inactive rides and full rides never appear', () {
    expect(
      matchingRides(
        [
          make(owner: 'me'),
          make().copyWith(active: false),
          make().copyWith(availableSeats: 0),
        ],
        filters,
        'me',
        now: now,
      ),
      isEmpty,
    );
  });
  test('offers and requests have separate role filters', () {
    final rides = [make(), make(id: 'request', kind: RideKind.request)];
    expect(
      matchingRides(rides, filters, 'me', now: now).single.kind,
      RideKind.offer,
    );
    expect(
      matchingRides(
        rides,
        filters.copyWith(kind: RideKind.request),
        'me',
        now: now,
      ).single.kind,
      RideKind.request,
    );
  });
  test('minimum seats, free-only and saved filters are combined', () {
    final rides = [
      make(id: 'free', seats: 3, price: 0),
      make(id: 'small', seats: 1, price: 0),
      make(id: 'paid'),
    ];
    final f = filters.copyWith(
      minimumSeats: 2,
      freeOnly: true,
      savedOnly: true,
    );
    expect(
      matchingRides(
        rides,
        f,
        'me',
        savedIds: {'free', 'paid'},
        now: now,
      ).single.id,
      'free',
    );
  });
  test('optional time window includes exactly 60 minutes but not 61', () {
    final f = filters.copyWith(timeMinutes: 17 * 60 + 30);
    final result = matchingRides(
      [
        make(id: 'at60', hour: 18, minute: 30),
        make(id: 'at61', hour: 18, minute: 31),
      ],
      f,
      'me',
      now: now,
    );
    expect(result.single.id, 'at60');
    expect(f.copyWith(clearTime: true).timeMinutes, isNull);
  });
  test('sort is stable by departure when contributions are equal', () {
    final rides = [
      make(id: 'late', hour: 18),
      make(id: 'early', hour: 16),
      make(id: 'free', hour: 19, price: 0),
    ];
    expect(matchingRides(rides, filters, 'me', now: now).first.id, 'early');
    expect(
      matchingRides(
        rides,
        filters.copyWith(sort: RideSort.lowestCost),
        'me',
        now: now,
      ).first.id,
      'free',
    );
  });
  test('driver may fulfil request only with their own compatible offer', () {
    final offer = make(owner: 'me'),
        request = make(id: 'request', kind: RideKind.request, seats: 2);
    expect(compatibleOfferForRequest(offer, request, 'me', now: now), isTrue);
    expect(
      compatibleOfferForRequest(offer, request, 'stranger', now: now),
      isFalse,
    );
    expect(
      compatibleOfferForRequest(
        offer.copyWith(availableSeats: 1),
        request,
        'me',
        now: now,
      ),
      isFalse,
    );
    expect(
      compatibleOfferForRequest(
        offer,
        make(kind: RideKind.request, hour: 19),
        'me',
        now: now,
      ),
      isFalse,
    );
  });
}
