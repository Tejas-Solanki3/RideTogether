import 'package:intl/intl.dart';

enum RideKind { offer, request }

enum MatchStatus { confirmed, cancelled }

enum RideSort { earliest, lowestCost }

class CampusPlace {
  final String id, name, subtitle;
  final double x, y;
  const CampusPlace(this.id, this.name, this.subtitle, this.x, this.y);
  static const all = [
    CampusPlace('north_gate', 'North Gate', 'Greenfield University', .22, .65),
    CampusPlace(
      'riverside_metro',
      'Riverside Metro',
      'Station entrance · 3.2 km away',
      .78,
      .25,
    ),
    CampusPlace(
      'central_library',
      'Central Library',
      'Main campus · Library circle',
      .49,
      .43,
    ),
    CampusPlace(
      'maple_hostel',
      'Maple Hostel',
      'West campus · Block A',
      .18,
      .27,
    ),
    CampusPlace(
      'innovation_hub',
      'Innovation Hub',
      'East campus · Academic block',
      .74,
      .62,
    ),
    CampusPlace(
      'sports_complex',
      'Sports Complex',
      'South campus · Court entrance',
      .45,
      .82,
    ),
    CampusPlace(
      'lakeside_cafe',
      'Lakeside Café',
      'Lake road · Main entrance',
      .66,
      .15,
    ),
  ];
  static CampusPlace byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => all.first);
}

DateTime defaultDeparture() {
  final now = DateTime.now();
  final afternoon = DateTime(now.year, now.month, now.day, 17, 30);
  return afternoon.isAfter(now.add(const Duration(minutes: 30)))
      ? afternoon
      : DateTime(now.year, now.month, now.day + 1, 17, 30);
}

String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
bool sameDay(DateTime a, DateTime b) => dayKey(a) == dayKey(b);
String timeLabel(DateTime d) => DateFormat('h:mm a').format(d);
String dateLabel(DateTime d, {bool long = false}) {
  final now = DateTime.now();
  if (sameDay(d, now)) return 'Today';
  if (sameDay(d, now.add(const Duration(days: 1)))) return 'Tomorrow';
  return DateFormat(long ? 'EEE, d MMM' : 'd MMM').format(d);
}

class Student {
  final String id, name, email, avatar;
  final bool emailVerified;
  const Student({
    required this.id,
    required this.name,
    required this.email,
    this.avatar = 'rohan',
    this.emailVerified = false,
  });
  String get firstName => name.split(' ').first;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar': avatar,
    'emailVerified': emailVerified,
  };
  factory Student.fromJson(Map<String, dynamic> j) => Student(
    id: j['id'],
    name: j['name'],
    email: j['email'],
    avatar: j['avatar'] ?? 'rohan',
    emailVerified: j['emailVerified'] ?? false,
  );
  static const demo = Student(
    id: 'demo_ishaan',
    name: 'Ishaan Mehta',
    email: 'ishaan@greenfield.edu',
    avatar: 'aarav',
  );
}

class Ride {
  final String id, ownerId, ownerName, ownerAvatar, originId, destinationId;
  final String campusId, vehicle, note;
  final RideKind kind;
  final DateTime departureAt, createdAt;
  final int totalSeats, availableSeats, contribution;
  final bool active;
  final String matchedId;
  const Ride({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerAvatar,
    required this.originId,
    required this.destinationId,
    required this.kind,
    required this.departureAt,
    required this.createdAt,
    required this.totalSeats,
    required this.availableSeats,
    this.contribution = 0,
    this.campusId = 'greenfield',
    this.vehicle = '',
    this.note = '',
    this.active = true,
    this.matchedId = '',
  });
  CampusPlace get origin => CampusPlace.byId(originId);
  CampusPlace get destination => CampusPlace.byId(destinationId);
  String get dateKey => dayKey(departureAt);
  Ride copyWith({int? availableSeats, bool? active, String? matchedId}) => Ride(
    id: id,
    ownerId: ownerId,
    ownerName: ownerName,
    ownerAvatar: ownerAvatar,
    originId: originId,
    destinationId: destinationId,
    kind: kind,
    departureAt: departureAt,
    createdAt: createdAt,
    totalSeats: totalSeats,
    availableSeats: availableSeats ?? this.availableSeats,
    contribution: contribution,
    campusId: campusId,
    vehicle: vehicle,
    note: note,
    active: active ?? this.active,
    matchedId: matchedId ?? this.matchedId,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'ownerAvatar': ownerAvatar,
    'originId': originId,
    'destinationId': destinationId,
    'kind': kind.name,
    'departureAt': departureAt.toIso8601String(),
    'dateKey': dateKey,
    'createdAt': createdAt.toIso8601String(),
    'totalSeats': totalSeats,
    'availableSeats': availableSeats,
    'contribution': contribution,
    'campusId': campusId,
    'vehicle': vehicle,
    'note': note,
    'active': active,
    'matchedId': matchedId,
  };
  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
    id: j['id'],
    ownerId: j['ownerId'],
    ownerName: j['ownerName'],
    ownerAvatar: j['ownerAvatar'] ?? '',
    originId: j['originId'],
    destinationId: j['destinationId'],
    kind: RideKind.values.byName(j['kind']),
    departureAt: DateTime.parse(j['departureAt']).toLocal(),
    createdAt: DateTime.parse(j['createdAt']).toLocal(),
    totalSeats: j['totalSeats'],
    availableSeats: j['availableSeats'],
    contribution: j['contribution'] ?? 0,
    campusId: j['campusId'] ?? 'greenfield',
    vehicle: j['vehicle'] ?? '',
    note: j['note'] ?? '',
    active: j['active'] ?? true,
    matchedId: j['matchedId'] ?? '',
  );
}

class RideMatch {
  final String id, offerId, requestId, driverId, riderId, driverName, riderName;
  final String driverAvatar,
      riderAvatar,
      originId,
      destinationId,
      vehicle,
      campusId;
  final DateTime departureAt, createdAt;
  final int seats, contribution;
  final MatchStatus status;
  const RideMatch({
    required this.id,
    required this.offerId,
    this.requestId = '',
    required this.driverId,
    required this.riderId,
    required this.driverName,
    required this.riderName,
    required this.driverAvatar,
    required this.riderAvatar,
    required this.originId,
    required this.destinationId,
    required this.departureAt,
    required this.createdAt,
    required this.seats,
    required this.contribution,
    this.vehicle = '',
    this.campusId = 'greenfield',
    this.status = MatchStatus.confirmed,
  });
  CampusPlace get origin => CampusPlace.byId(originId);
  CampusPlace get destination => CampusPlace.byId(destinationId);
  bool isDriver(String uid) => driverId == uid;
  RideMatch cancelled() => RideMatch(
    id: id,
    offerId: offerId,
    requestId: requestId,
    driverId: driverId,
    riderId: riderId,
    driverName: driverName,
    riderName: riderName,
    driverAvatar: driverAvatar,
    riderAvatar: riderAvatar,
    originId: originId,
    destinationId: destinationId,
    departureAt: departureAt,
    createdAt: createdAt,
    seats: seats,
    contribution: contribution,
    vehicle: vehicle,
    campusId: campusId,
    status: MatchStatus.cancelled,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'offerId': offerId,
    'requestId': requestId,
    'driverId': driverId,
    'riderId': riderId,
    'driverName': driverName,
    'riderName': riderName,
    'driverAvatar': driverAvatar,
    'riderAvatar': riderAvatar,
    'originId': originId,
    'destinationId': destinationId,
    'departureAt': departureAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'seats': seats,
    'contribution': contribution,
    'vehicle': vehicle,
    'campusId': campusId,
    'status': status.name,
    'participants': [driverId, riderId],
  };
  factory RideMatch.fromJson(Map<String, dynamic> j) => RideMatch(
    id: j['id'],
    offerId: j['offerId'],
    requestId: j['requestId'] ?? '',
    driverId: j['driverId'],
    riderId: j['riderId'],
    driverName: j['driverName'],
    riderName: j['riderName'],
    driverAvatar: j['driverAvatar'] ?? '',
    riderAvatar: j['riderAvatar'] ?? '',
    originId: j['originId'],
    destinationId: j['destinationId'],
    departureAt: DateTime.parse(j['departureAt']).toLocal(),
    createdAt: DateTime.parse(j['createdAt']).toLocal(),
    seats: j['seats'],
    contribution: j['contribution'] ?? 0,
    vehicle: j['vehicle'] ?? '',
    campusId: j['campusId'] ?? 'greenfield',
    status: MatchStatus.values.byName(j['status']),
  );
}

class ChatMessage {
  final String id, senderId, text;
  final DateTime createdAt;
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'],
    senderId: j['senderId'],
    text: j['text'],
    createdAt: DateTime.parse(j['createdAt']).toLocal(),
  );
}

class RideFilters {
  final String originId, destinationId;
  final DateTime date;
  final RideKind kind;
  final int minimumSeats;
  final bool freeOnly, savedOnly;
  final int? timeMinutes;
  final RideSort sort;
  const RideFilters({
    required this.originId,
    required this.destinationId,
    required this.date,
    this.kind = RideKind.offer,
    this.minimumSeats = 1,
    this.freeOnly = false,
    this.savedOnly = false,
    this.timeMinutes,
    this.sort = RideSort.earliest,
  });
  factory RideFilters.initial() => RideFilters(
    originId: 'north_gate',
    destinationId: 'riverside_metro',
    date: defaultDeparture(),
  );
  RideFilters copyWith({
    String? originId,
    String? destinationId,
    DateTime? date,
    RideKind? kind,
    int? minimumSeats,
    bool? freeOnly,
    bool? savedOnly,
    int? timeMinutes,
    bool clearTime = false,
    RideSort? sort,
  }) => RideFilters(
    originId: originId ?? this.originId,
    destinationId: destinationId ?? this.destinationId,
    date: date ?? this.date,
    kind: kind ?? this.kind,
    minimumSeats: minimumSeats ?? this.minimumSeats,
    freeOnly: freeOnly ?? this.freeOnly,
    savedOnly: savedOnly ?? this.savedOnly,
    timeMinutes: clearTime ? null : (timeMinutes ?? this.timeMinutes),
    sort: sort ?? this.sort,
  );
}

class RideException implements Exception {
  final String message;
  const RideException(this.message);
  @override
  String toString() => message;
}
