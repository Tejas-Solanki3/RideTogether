import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/matching.dart';
import '../domain/models.dart';
import 'ride_repository.dart';

class FirestoreRideRepository implements RideRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  FirestoreRideRepository(this.db, this.auth);
  @override
  bool get isDemo => false;
  CollectionReference<Map<String, dynamic>> get rides => db.collection('rides');
  CollectionReference<Map<String, dynamic>> get matches =>
      db.collection('matches');
  Student _student(User u, {String university = 'Greenfield University'}) => Student(
    id: u.uid,
    name: u.displayName ?? (u.email ?? 'Student').split('@').first,
    email: u.email ?? '',
    avatar: '',
    emailVerified: true, // Bypassed for development
    university: university,
  );
  void _require(Student student) {
    if (auth.currentUser?.uid != student.id) {
      throw const RideException('Please sign in to continue.');
    }
  }

  Map<String, dynamic> _json(Map<String, dynamic> data) {
    final j = Map<String, dynamic>.from(data);
    for (final key in ['departureAt', 'createdAt']) {
      final value = j[key];
      if (value is Timestamp) j[key] = value.toDate().toIso8601String();
      if (value == null && key == 'createdAt') {
        j[key] = DateTime.now().toIso8601String();
      }
    }
    return j;
  }

  Map<String, dynamic> _rideData(Ride r) => {
    ...r.toJson(),
    'departureAt': Timestamp.fromDate(r.departureAt),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'lastMatchId': '',
  };
  Map<String, dynamic> _matchData(RideMatch m) => {
    ...m.toJson(),
    'departureAt': Timestamp.fromDate(m.departureAt),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  @override
  Stream<Student?> watchSession() =>
      auth.userChanges().asyncMap((u) async {
        if (u == null) return null;
        try {
          final doc = await db.collection('students').doc(u.uid).get();
          final uni = (doc.data()?['university'] as String?) ?? 'Greenfield University';
          return _student(u, university: uni);
        } catch (_) {
          return _student(u);
        }
      });
  @override
  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register(String name, String email, String password, {String university = ''}) async {
    final result = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user!.updateDisplayName(name.trim());
    await db.collection('students').doc(result.user!.uid).set({
      'university': university.isEmpty ? 'Greenfield University' : university,
    });
    await result.user!.sendEmailVerification();
    await result.user!.reload();
  }

  @override
  Future<void> signOut() => auth.signOut();
  @override
  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());
  @override
  Future<void> resendVerification() =>
      auth.currentUser!.sendEmailVerification();
  @override
  Future<void> refreshUser() async {
    await auth.currentUser?.reload();
    await auth.currentUser?.getIdToken(true);
  }

  @override
  Stream<List<Ride>> watchRides() => rides
      .where('campusId', isEqualTo: 'greenfield')
      .orderBy('departureAt')
      .snapshots()
      .map((s) => s.docs.map((d) => Ride.fromJson(_json(d.data()))).toList());
  @override
  Stream<List<RideMatch>> watchMatches(String uid) => matches
      .where('participants', arrayContains: uid)
      .orderBy('departureAt')
      .snapshots()
      .map(
        (s) => s.docs.map((d) => RideMatch.fromJson(_json(d.data()))).toList(),
      );
  @override
  Stream<List<ChatMessage>> watchMessages(String matchId) => matches
      .doc(matchId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => ChatMessage.fromJson(_json(d.data()))).toList(),
      );
  @override
  Future<void> postRide(Ride ride, Student student) async {
    _require(student);
    validateRide(ride, student);
    await rides.doc(ride.id).set(_rideData(ride));
  }

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
    campusId: offer.campusId,
  );
  @override
  Future<RideMatch> joinOffer(
    String rideId,
    Student student, {
    String requestId = '',
  }) async {
    _require(student);
    return db.runTransaction((tx) async {
      final offerRef = rides.doc(rideId);
      final offerDoc = await tx.get(offerRef);
      if (!offerDoc.exists) {
        throw const RideException('This ride is no longer available.');
      }
      final offer = Ride.fromJson(_json(offerDoc.data()!));
      final matchRef = matches.doc('${rideId}_${student.id}');
      final existing = await tx.get(matchRef);
      if (existing.exists) {
        final match = RideMatch.fromJson(_json(existing.data()!));
        if (match.status == MatchStatus.confirmed) return match;
        throw const RideException(
          'This connection was cancelled. Choose another ride.',
        );
      }
      if (offer.ownerId == student.id) {
        throw const RideException('You cannot join your own ride.');
      }
      if (offer.kind != RideKind.offer ||
          !offer.active ||
          !offer.departureAt.isAfter(DateTime.now())) {
        throw const RideException('This ride is no longer available.');
      }
      Ride? request;
      DocumentReference<Map<String, dynamic>>? requestRef;
      if (requestId.isNotEmpty) {
        requestRef = rides.doc(requestId);
        final requestDoc = await tx.get(requestRef);
        if (!requestDoc.exists) {
          throw const RideException('Your request is no longer available.');
        }
        request = Ride.fromJson(_json(requestDoc.data()!));
        if (request.ownerId != student.id ||
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
      tx.set(matchRef, _matchData(match));
      tx.update(offerRef, {
        'availableSeats': offer.availableSeats - reserved,
        'lastMatchId': match.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (requestRef != null) {
        tx.update(requestRef, {
          'availableSeats': 0,
          'active': false,
          'matchedId': match.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return match;
    });
  }

  @override
  Future<RideMatch> fulfilRequest(
    String requestId,
    String offerId,
    Student driver,
  ) async {
    _require(driver);
    return db.runTransaction((tx) async {
      final requestRef = rides.doc(requestId), offerRef = rides.doc(offerId);
      final requestDoc = await tx.get(requestRef),
          offerDoc = await tx.get(offerRef);
      if (!requestDoc.exists || !offerDoc.exists) {
        throw const RideException('This ride is no longer available.');
      }
      final request = Ride.fromJson(_json(requestDoc.data()!));
      final offer = Ride.fromJson(_json(offerDoc.data()!));
      if (!compatibleOfferForRequest(offer, request, driver.id)) {
        throw const RideException(
          'Your offer must match the route, date, seats, and departure within 60 minutes.',
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
        requestId: requestId,
      );
      final matchRef = matches.doc(match.id);
      if ((await tx.get(matchRef)).exists) {
        throw const RideException(
          'You have already connected with this student on this ride.',
        );
      }
      tx.set(matchRef, _matchData(match));
      tx.update(offerRef, {
        'availableSeats': offer.availableSeats - request.totalSeats,
        'lastMatchId': match.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(requestRef, {
        'availableSeats': 0,
        'active': false,
        'matchedId': match.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return match;
    });
  }

  @override
  Future<void> cancelMatch(String matchId, Student student) async {
    _require(student);
    await db.runTransaction((tx) async {
      final matchRef = matches.doc(matchId);
      final matchDoc = await tx.get(matchRef);
      if (!matchDoc.exists) throw const RideException('Connection not found.');
      final match = RideMatch.fromJson(_json(matchDoc.data()!));
      if (match.driverId != student.id && match.riderId != student.id) {
        throw const RideException('You can only cancel your own connections.');
      }
      if (match.status == MatchStatus.cancelled) return;
      if (!match.departureAt.isAfter(DateTime.now())) {
        throw const RideException('Past rides cannot be cancelled.');
      }
      final offerRef = rides.doc(match.offerId),
          offerDoc = await tx.get(offerRef);
      if (!offerDoc.exists) {
        throw const RideException('The ride could not be found.');
      }
      final offer = Ride.fromJson(_json(offerDoc.data()!));
      DocumentSnapshot<Map<String, dynamic>>? requestDoc;
      if (match.requestId.isNotEmpty) {
        requestDoc = await tx.get(rides.doc(match.requestId));
      }
      tx.update(matchRef, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(offerRef, {
        'availableSeats': offer.availableSeats + match.seats,
        'lastMatchId': match.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (requestDoc?.exists == true) {
        tx.update(requestDoc!.reference, {
          'availableSeats': requestDoc.data()!['totalSeats'],
          'active': true,
          'matchedId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> sendMessage(String matchId, Student student, String text) async {
    _require(student);
    final message = text.trim();
    if (message.isEmpty || message.length > 1000) {
      throw const RideException(
        'Messages must be between 1 and 1,000 characters.',
      );
    }
    final ref = matches.doc(matchId).collection('messages').doc();
    await ref.set({
      'id': ref.id,
      'senderId': student.id,
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> resetDemo() async =>
      throw const RideException('Reset is only available in the local demo.');
  @override
  void dispose() {}
}
