import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/matching.dart';
import '../domain/models.dart';
import 'ride_repository.dart';

/// Fully offline demo. Its mutation queue gives the same all-or-nothing seat
/// reservation semantics as the Firestore transaction, within one app instance.
/// It is deliberately NOT authentication or a multi-device backend.
class DemoRideRepository implements RideRepository {
  final SharedPreferences prefs;
  final _changes = StreamController<void>.broadcast();
  final _auth = StreamController<Student?>.broadcast();
  final Map<String, Ride> _rides = {};
  final Map<String, RideMatch> _matches = {};
  final Map<String, List<ChatMessage>> _messages = {};
  Student? _student;
  Future<void> _queue = Future.value();
  static const storageKey = 'ridetogether_demo_v1';
  DemoRideRepository(this.prefs) {
    final saved = prefs.getString(storageKey);
    if (saved != null) {
      try {
        final j = jsonDecode(saved) as Map<String, dynamic>;
        // v1 opened automatically as a sample account. v2 requires an explicit login.
        _student = j['authFlowVersion'] == 2 && j['student'] != null
            ? Student.fromJson(j['student'])
            : null;
        // Update the canonical demo picture on existing saved sessions too.
        if (_student?.id == Student.demo.id) _student = Student.demo;
        for (final r in j['rides']) {
          final ride = Ride.fromJson(r);
          _rides[ride.id] = ride;
        }
        for (final m in j['matches']) {
          final match = RideMatch.fromJson(m);
          _matches[match.id] = match;
        }
        (j['messages'] as Map<String, dynamic>).forEach((key, list) {
          _messages[key] = (list as List)
              .map((e) => ChatMessage.fromJson(e))
              .toList();
        });
      } catch (_) {
        _seed();
      }
    } else {
      _seed();
    }
  }
  @override
  bool get isDemo => true;
  void _seed() {
    _student = null;
    _rides.clear();
    _matches.clear();
    _messages.clear();
    final base = defaultDeparture();
    void add(
      String id,
      String uid,
      String name,
      String avatar,
      int minutes,
      int seats,
      int price,
      String car, {
      RideKind kind = RideKind.offer,
      String origin = 'north_gate',
      String destination = 'riverside_metro',
    }) {
      _rides[id] = Ride(
        id: id,
        ownerId: uid,
        ownerName: name,
        ownerAvatar: avatar,
        originId: origin,
        destinationId: destination,
        kind: kind,
        departureAt: base.add(Duration(minutes: minutes)),
        createdAt: DateTime.now(),
        totalSeats: seats,
        availableSeats: seats,
        contribution: price,
        vehicle: car,
        note: kind == RideKind.offer
            ? 'Meet by the security booth. A small backpack is welcome.'
            : 'Heading to the metro after class. Happy to share fuel costs.',
      );
    }

    add(
      'offer_aarav',
      'demo_aarav',
      'Aarav Sharma',
      'aarav',
      0,
      3,
      40,
      'Hyundai i20 · White',
    );
    add(
      'offer_ananya',
      'demo_ananya',
      'Ananya Rao',
      'ananya',
      15,
      2,
      30,
      'Tata Nexon EV · Silver',
    );
    add(
      'offer_rohan',
      'demo_rohan',
      'Rohan Desai',
      'rohan',
      45,
      1,
      0,
      'Maruti Swift · Blue',
    );
    add(
      'offer_library',
      'demo_aarav',
      'Aarav Sharma',
      'aarav',
      60,
      2,
      20,
      'Hyundai i20 · White',
      destination: 'central_library',
    );
    add(
      'offer_return',
      'demo_ananya',
      'Ananya Rao',
      'ananya',
      24 * 60,
      3,
      30,
      'Tata Nexon EV · Silver',
      origin: 'riverside_metro',
      destination: 'north_gate',
    );
    add(
      'request_sneha',
      'demo_sneha',
      'Sneha Kapoor',
      'ananya',
      10,
      1,
      40,
      '',
      kind: RideKind.request,
    );
    add(
      'request_karan',
      'demo_karan',
      'Karan Patel',
      'aarav',
      35,
      2,
      35,
      '',
      kind: RideKind.request,
    );
    add(
      'own_offer',
      Student.demo.id,
      Student.demo.name,
      Student.demo.avatar,
      30,
      4,
      35,
      'Honda City · Grey',
    );
    final own = _rides['own_offer']!;
    _rides[own.id] = own.copyWith(availableSeats: 3);
    final initial = _makeMatch(
      own,
      const Student(
        id: 'demo_priya',
        name: 'Priya Nair',
        email: 'priya@greenfield.edu',
        avatar: 'ananya',
      ),
      1,
    );
    _matches[initial.id] = initial;
    _messages[initial.id] = [
      ChatMessage(
        id: 'welcome',
        senderId: 'demo_priya',
        text:
            'Hi Ishaan! I’ll meet you at the North Gate security booth. Thanks for the ride!',
        createdAt: DateTime.now(),
      ),
    ];
  }

  Future<void> _persist() async {
    final saved = await prefs.setString(
      storageKey,
      jsonEncode({
        'authFlowVersion': 2,
        'student': _student?.toJson(),
        'rides': _rides.values.map((r) => r.toJson()).toList(),
        'matches': _matches.values.map((m) => m.toJson()).toList(),
        'messages': _messages.map(
          (k, v) => MapEntry(k, v.map((m) => m.toJson()).toList()),
        ),
      }),
    );
    if (!saved) {
      throw const RideException(
        'Couldn’t save your changes. Please try again.',
      );
    }
    _changes.add(null);
  }

  Future<T> _atomic<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _queue = _queue.then((_) async {
      final previousRides = Map<String, Ride>.of(_rides);
      final previousMatches = Map<String, RideMatch>.of(_matches);
      final previousMessages = _messages.map(
        (key, value) => MapEntry(key, List<ChatMessage>.of(value)),
      );
      final previousStudent = _student;
      try {
        result.complete(await action());
      } catch (e, s) {
        _rides
          ..clear()
          ..addAll(previousRides);
        _matches
          ..clear()
          ..addAll(previousMatches);
        _messages
          ..clear()
          ..addAll(previousMessages);
        _student = previousStudent;
        result.completeError(e, s);
      }
    });
    return result.future;
  }

  void _require(Student student) {
    if (_student?.id != student.id) {
      throw const RideException('Please sign in to continue.');
    }
  }

  @override
  Stream<Student?> watchSession() async* {
    yield _student;
    yield* _auth.stream;
  }

  @override
  Stream<List<Ride>> watchRides() async* {
    yield _rides.values.toList();
    yield* _changes.stream.map((_) => _rides.values.toList());
  }

  @override
  Stream<List<RideMatch>> watchMatches(String uid) async* {
    List<RideMatch> value() =>
        _matches.values
            .where((m) => m.driverId == uid || m.riderId == uid)
            .toList()
          ..sort((a, b) => a.departureAt.compareTo(b.departureAt));
    yield value();
    yield* _changes.stream.map((_) => value());
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String matchId) async* {
    List<ChatMessage> value() => List.of(_messages[matchId] ?? []);
    yield value();
    yield* _changes.stream.map((_) => value());
  }

  @override
  Future<void> signIn(String email, String password) async {
    _student = email.trim().toLowerCase() == Student.demo.email
        ? Student.demo
        : Student(
            id: 'demo_${email.trim().toLowerCase()}',
            name: email
                .split('@')
                .first
                .split(RegExp(r'[._]'))
                .map(
                  (s) =>
                      s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}',
                )
                .join(' '),
            email: email.trim().toLowerCase(),
          );
    await _persist();
    _auth.add(_student);
  }

  @override
  Future<void> register(String name, String email, String password, {String university = ''}) async {
    _student = Student(
      id: 'demo_${email.trim().toLowerCase()}',
      name: name.trim(),
      email: email.trim(),
      university: university.isEmpty ? 'Greenfield University' : university,
    );
    await _persist();
    _auth.add(_student);
  }

  @override
  Future<void> signOut() async {
    _student = null;
    await _persist();
    _auth.add(null);
  }

  @override
  Future<void> resetPassword(String email) async => throw const RideException(
    'Demo accounts have no real password. Use any password with 6+ characters to sign in.',
  );
  @override
  Future<void> resendVerification() async {}
  @override
  Future<void> refreshUser() async {
    _auth.add(_student);
  }

  @override
  Future<void> postRide(Ride ride, Student student) => _atomic(() async {
    _require(student);
    validateRide(ride, student);
    if (_rides.containsKey(ride.id)) {
      throw const RideException('This ride is already posted.');
    }
    _rides[ride.id] = ride;
    await _persist();
  });
  RideMatch _makeMatch(
    Ride offer,
    Student rider,
    int seats, {
    String requestId = '',
  }) => RideMatch(
    id: '${offer.id}_${rider.id}',
    offerId: offer.id,
    requestId: requestId,
    driverId: offer.ownerId,
    driverName: offer.ownerName,
    driverAvatar: offer.ownerAvatar,
    riderId: rider.id,
    riderName: rider.name,
    riderAvatar: rider.avatar,
    originId: offer.originId,
    destinationId: offer.destinationId,
    departureAt: offer.departureAt,
    createdAt: DateTime.now(),
    seats: seats,
    contribution: offer.contribution,
    vehicle: offer.vehicle,
  );
  @override
  Future<RideMatch> joinOffer(
    String rideId,
    Student student, {
    String requestId = '',
  }) => _atomic(() async {
    _require(student);
    final offer = _rides[rideId];
    if (offer == null || offer.kind != RideKind.offer || !offer.active) {
      throw const RideException('This ride is no longer available.');
    }
    if (offer.ownerId == student.id) {
      throw const RideException('You cannot join your own ride.');
    }
    if (!offer.departureAt.isAfter(DateTime.now())) {
      throw const RideException('This ride has already departed.');
    }
    final existing = _matches['${offer.id}_${student.id}'];
    if (existing?.status == MatchStatus.confirmed) return existing!;
    if (existing != null) {
      throw const RideException(
        'This connection was cancelled. Choose another ride.',
      );
    }
    Ride? request;
    if (requestId.isNotEmpty) {
      request = _rides[requestId];
      if (request == null ||
          request.ownerId != student.id ||
          !compatibleOfferForRequest(offer, request, offer.ownerId)) {
        throw const RideException(
          'Your request no longer matches this offer. Try another ride.',
        );
      }
    }
    final reserved = request?.totalSeats ?? 1;
    if (offer.availableSeats < reserved) {
      throw const RideException(
        'Not enough seats are available. Try another ride.',
      );
    }
    final match = _makeMatch(offer, student, reserved, requestId: requestId);
    _rides[offer.id] = offer.copyWith(
      availableSeats: offer.availableSeats - reserved,
    );
    if (request != null) {
      _rides[request.id] = request.copyWith(
        active: false,
        availableSeats: 0,
        matchedId: match.id,
      );
    }
    _matches[match.id] = match;
    await _persist();
    return match;
  });
  @override
  Future<RideMatch> fulfilRequest(
    String requestId,
    String offerId,
    Student driver,
  ) => _atomic(() async {
    _require(driver);
    final request = _rides[requestId], offer = _rides[offerId];
    if (request == null ||
        offer == null ||
        !compatibleOfferForRequest(offer, request, driver.id)) {
      throw const RideException(
        'Choose your offer with the same route, date, enough seats, and a time within 60 minutes.',
      );
    }
    final id = '${offer.id}_${request.ownerId}';
    if (_matches.containsKey(id)) {
      throw const RideException(
        'You have already connected with this student on this ride.',
      );
    }
    final rider = Student(
      id: request.ownerId,
      name: request.ownerName,
      email: '',
      avatar: request.ownerAvatar,
    );
    final match = _makeMatch(
      offer,
      rider,
      request.totalSeats,
      requestId: request.id,
    );
    _rides[offer.id] = offer.copyWith(
      availableSeats: offer.availableSeats - request.totalSeats,
    );
    _rides[request.id] = request.copyWith(
      active: false,
      availableSeats: 0,
      matchedId: match.id,
    );
    _matches[match.id] = match;
    await _persist();
    return match;
  });
  @override
  Future<void> cancelMatch(String matchId, Student student) => _atomic(
    () async {
      _require(student);
      final match = _matches[matchId];
      if (match == null ||
          (match.driverId != student.id && match.riderId != student.id)) {
        throw const RideException('You can only cancel your own connections.');
      }
      if (match.status == MatchStatus.cancelled) return;
      if (!match.departureAt.isAfter(DateTime.now())) {
        throw const RideException('Past rides cannot be cancelled.');
      }
      final offer = _rides[match.offerId]!;
      _rides[offer.id] = offer.copyWith(
        availableSeats: offer.availableSeats + match.seats,
      );
      if (match.requestId.isNotEmpty) {
        final request = _rides[match.requestId]!;
        _rides[request.id] = request.copyWith(
          active: true,
          availableSeats: request.totalSeats,
          matchedId: '',
        );
      }
      _matches[matchId] = match.cancelled();
      await _persist();
    },
  );
  @override
  Future<void> sendMessage(String matchId, Student student, String text) =>
      _atomic(() async {
        _require(student);
        final match = _matches[matchId];
        if (match == null ||
            match.status != MatchStatus.confirmed ||
            (match.driverId != student.id && match.riderId != student.id)) {
          throw const RideException(
            'Chat is only available for active connections.',
          );
        }
        if (text.trim().isEmpty || text.trim().length > 1000) {
          throw const RideException(
            'Messages must be between 1 and 1,000 characters.',
          );
        }
        (_messages[matchId] ??= []).add(
          ChatMessage(
            id: const Uuid().v4(),
            senderId: student.id,
            text: text.trim(),
            createdAt: DateTime.now(),
          ),
        );
        await _persist();
      });
  @override
  Future<void> resetDemo() => _atomic(() async {
    _seed();
    await _persist();
    _auth.add(_student);
  });
  @override
  void dispose() {
    _changes.close();
    _auth.close();
  }
}
