import 'models.dart';

/// Exact, directional campus endpoints and local departure day. An optional
/// time preference allows a ±60 minute window. No fuzzy/unsafe pickup matches.
List<Ride> matchingRides(
  List<Ride> rides,
  RideFilters filters,
  String uid, {
  Set<String> savedIds = const {},
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final matches = rides.where((ride) {
    if (!ride.active || ride.ownerId == uid || ride.kind != filters.kind) {
      return false;
    }
    if (ride.originId != filters.originId ||
        ride.destinationId != filters.destinationId) {
      return false;
    }
    if (!sameDay(ride.departureAt, filters.date) ||
        !ride.departureAt.isAfter(current)) {
      return false;
    }
    if (ride.availableSeats < filters.minimumSeats) return false;
    if (filters.freeOnly && ride.contribution != 0) return false;
    if (filters.savedOnly && !savedIds.contains(ride.id)) return false;
    if (filters.timeMinutes != null) {
      final minutes = ride.departureAt.hour * 60 + ride.departureAt.minute;
      if ((minutes - filters.timeMinutes!).abs() > 60) return false;
    }
    return true;
  }).toList();
  matches.sort(
    (a, b) => filters.sort == RideSort.lowestCost
        ? (a.contribution == b.contribution
              ? a.departureAt.compareTo(b.departureAt)
              : a.contribution.compareTo(b.contribution))
        : a.departureAt.compareTo(b.departureAt),
  );
  return matches;
}

bool compatibleOfferForRequest(
  Ride offer,
  Ride request,
  String driverId, {
  DateTime? now,
}) =>
    offer.kind == RideKind.offer &&
    request.kind == RideKind.request &&
    offer.ownerId == driverId &&
    request.ownerId != driverId &&
    offer.active &&
    request.active &&
    offer.campusId == request.campusId &&
    offer.originId == request.originId &&
    offer.destinationId == request.destinationId &&
    sameDay(offer.departureAt, request.departureAt) &&
    offer.departureAt.difference(request.departureAt).abs() <=
        const Duration(minutes: 60) &&
    offer.departureAt.isAfter(now ?? DateTime.now()) &&
    offer.availableSeats >= request.totalSeats;

void validateRide(Ride ride, Student student) {
  if (ride.ownerId != student.id) {
    throw const RideException('You can only post your own rides.');
  }
  if (ride.ownerName.trim().length < 2 || ride.ownerName.length > 80) {
    throw const RideException(
      'Use a student name between 2 and 80 characters.',
    );
  }
  if (ride.vehicle.length > 60) {
    throw const RideException(
      'Keep your vehicle description under 60 characters.',
    );
  }
  if (ride.campusId != 'greenfield' ||
      !ride.active ||
      ride.matchedId.isNotEmpty) {
    throw const RideException('Post a new, active ride for your campus.');
  }
  if (ride.departureAt.isAfter(DateTime.now().add(const Duration(days: 366)))) {
    throw const RideException('Choose a date within the next year.');
  }
  final ids = CampusPlace.all.map((p) => p.id).toSet();
  if (!ids.contains(ride.originId) || !ids.contains(ride.destinationId)) {
    throw const RideException('Choose a campus pickup and drop-off point.');
  }
  if (ride.originId == ride.destinationId) {
    throw const RideException('Pickup and destination must be different.');
  }
  if (!ride.departureAt.isAfter(DateTime.now())) {
    throw const RideException('Choose a departure time in the future.');
  }
  if (ride.totalSeats < 1 ||
      ride.totalSeats > 6 ||
      ride.availableSeats != ride.totalSeats) {
    throw const RideException('Seats must be between 1 and 6.');
  }
  if (ride.contribution < 0 || ride.contribution > 500) {
    throw const RideException('Contribution must be between ₹0 and ₹500.');
  }
  if (ride.note.length > 300) {
    throw const RideException('Keep your pickup note under 300 characters.');
  }
  if (ride.kind == RideKind.offer && ride.vehicle.trim().length < 2) {
    throw const RideException(
      'Add a vehicle description so riders can find you.',
    );
  }
}
