import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ride_together/data/demo_repository.dart';
import 'package:ride_together/domain/models.dart';

void main() {
  late DemoRideRepository repo;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = DemoRideRepository(prefs);
  });
  tearDown(() => repo.dispose());
  Future<Ride> ride(String id) async =>
      (await repo.watchRides().first).firstWhere((r) => r.id == id);
  test(
    'starts signed in as sample student with realistic offers and a driver-side match',
    () async {
      expect((await repo.watchSession().first)?.id, Student.demo.id);
      expect((await repo.watchRides().first).length, 8);
      expect(
        (await repo.watchMatches(Student.demo.id).first).single.driverId,
        Student.demo.id,
      );
    },
  );
  test('joining creates a rider-side match and consumes one seat', () async {
    final before = await ride('offer_aarav');
    final match = await repo.joinOffer('offer_aarav', Student.demo);
    expect(match.riderId, Student.demo.id);
    expect(
      (await ride('offer_aarav')).availableSeats,
      before.availableSeats - 1,
    );
    expect((await repo.watchMatches(Student.demo.id).first).length, 2);
  });
  test('concurrent duplicate joins are idempotent', () async {
    final results = await Future.wait([
      repo.joinOffer('offer_aarav', Student.demo),
      repo.joinOffer('offer_aarav', Student.demo),
    ]);
    expect(results[0].id, results[1].id);
    expect((await ride('offer_aarav')).availableSeats, 2);
  });
  test(
    'last seat cannot be overbooked by sequential different accounts',
    () async {
      await repo.joinOffer('offer_rohan', Student.demo);
      await repo.signIn('other@greenfield.edu', 'demo123');
      final other = (await repo.watchSession().first)!;
      await expectLater(
        repo.joinOffer('offer_rohan', other),
        throwsA(isA<RideException>()),
      );
      expect((await ride('offer_rohan')).availableSeats, 0);
    },
  );
  test('cancelling returns seats exactly once', () async {
    final match = await repo.joinOffer('offer_aarav', Student.demo);
    await repo.cancelMatch(match.id, Student.demo);
    await repo.cancelMatch(match.id, Student.demo);
    expect((await ride('offer_aarav')).availableSeats, 3);
    expect(
      (await repo.watchMatches(Student.demo.id).first).last.status,
      isNotNull,
    );
    await expectLater(
      repo.joinOffer('offer_aarav', Student.demo),
      throwsA(isA<RideException>()),
    );
  });
  test(
    'driver fulfilment reserves every requested seat and reopens request on cancel',
    () async {
      final match = await repo.fulfilRequest(
        'request_karan',
        'own_offer',
        Student.demo,
      );
      expect(match.seats, 2);
      expect((await ride('own_offer')).availableSeats, 1);
      expect((await ride('request_karan')).active, isFalse);
      await repo.cancelMatch(match.id, Student.demo);
      expect((await ride('own_offer')).availableSeats, 3);
      expect((await ride('request_karan')).availableSeats, 2);
      expect((await ride('request_karan')).active, isTrue);
    },
  );
  test('incompatible driver response changes nothing', () async {
    await expectLater(
      repo.fulfilRequest('request_karan', 'offer_library', Student.demo),
      throwsA(isA<RideException>()),
    );
    expect((await ride('request_karan')).active, isTrue);
  });
  test('streams expose updated availability live', () async {
    final observed = <int>[];
    final sub = repo.watchRides().listen(
      (rides) => observed.add(
        rides.firstWhere((r) => r.id == 'offer_aarav').availableSeats,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await repo.joinOffer('offer_aarav', Student.demo);
    await Future<void>.delayed(Duration.zero);
    expect(observed, containsAllInOrder([3, 2]));
    await sub.cancel();
  });
  test('chat persists and strangers cannot send into it', () async {
    final match = await repo.joinOffer('offer_aarav', Student.demo);
    await repo.sendMessage(match.id, Student.demo, 'I’m by the gate.');
    expect(
      (await repo.watchMessages(match.id).first).single.text,
      'I’m by the gate.',
    );
    await repo.signIn('other@greenfield.edu', 'demo123');
    final other = (await repo.watchSession().first)!;
    await expectLater(
      repo.sendMessage(match.id, other, 'Intrusion'),
      throwsA(isA<RideException>()),
    );
  });
  test('cancelled chat is read-only', () async {
    final match = await repo.joinOffer('offer_aarav', Student.demo);
    await repo.cancelMatch(match.id, Student.demo);
    await expectLater(
      repo.sendMessage(match.id, Student.demo, 'Hi'),
      throwsA(isA<RideException>()),
    );
  });
  test('saved data survives repository reconstruction', () async {
    final match = await repo.joinOffer('offer_aarav', Student.demo);
    await repo.sendMessage(match.id, Student.demo, 'Hello again.');
    final copy = DemoRideRepository(prefs);
    expect(
      (await copy.watchRides().first)
          .firstWhere((r) => r.id == 'offer_aarav')
          .availableSeats,
      2,
    );
    expect(
      (await copy.watchMessages(match.id).first).single.text,
      'Hello again.',
    );
    copy.dispose();
  });
  test(
    'posts validate route, seats, ownership, future date and vehicle',
    () async {
      final r = Ride(
        id: 'new',
        ownerId: Student.demo.id,
        ownerName: Student.demo.name,
        ownerAvatar: 'rohan',
        originId: 'north_gate',
        destinationId: 'central_library',
        kind: RideKind.offer,
        departureAt: defaultDeparture(),
        createdAt: DateTime.now(),
        totalSeats: 2,
        availableSeats: 2,
        vehicle: 'Honda City',
      );
      await repo.postRide(r, Student.demo);
      expect((await ride('new')).ownerId, Student.demo.id);
      await expectLater(
        repo.postRide(r, Student.demo),
        throwsA(isA<RideException>()),
      );
      await repo.signOut();
      await expectLater(
        repo.postRide(r, Student.demo),
        throwsA(isA<RideException>()),
      );
    },
  );
  test('demo reset restores sample data and session', () async {
    await repo.joinOffer('offer_aarav', Student.demo);
    await repo.resetDemo();
    expect((await ride('offer_aarav')).availableSeats, 3);
    expect((await repo.watchMatches(Student.demo.id).first).length, 1);
  });
  test(
    'rider can fulfil their own multi-seat request when joining an offer',
    () async {
      final request = Ride(
        id: 'group_request',
        ownerId: Student.demo.id,
        ownerName: Student.demo.name,
        ownerAvatar: Student.demo.avatar,
        originId: 'north_gate',
        destinationId: 'riverside_metro',
        kind: RideKind.request,
        departureAt: defaultDeparture(),
        createdAt: DateTime.now(),
        totalSeats: 2,
        availableSeats: 2,
      );
      await repo.postRide(request, Student.demo);
      final match = await repo.joinOffer(
        'offer_aarav',
        Student.demo,
        requestId: request.id,
      );
      expect(match.seats, 2);
      expect(match.requestId, request.id);
      expect((await ride('offer_aarav')).availableSeats, 1);
      expect((await ride(request.id)).active, isFalse);
      await repo.cancelMatch(match.id, Student.demo);
      expect((await ride(request.id)).active, isTrue);
      expect((await ride('offer_aarav')).availableSeats, 3);
    },
  );
}
