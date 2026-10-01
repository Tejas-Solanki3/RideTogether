import '../domain/models.dart';

abstract class RideRepository {
  bool get isDemo;
  Stream<Student?> watchSession();
  Future<void> signIn(String email, String password);
  Future<void> register(String name, String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> resendVerification();
  Future<void> refreshUser();
  Stream<List<Ride>> watchRides();
  Stream<List<RideMatch>> watchMatches(String uid);
  Stream<List<ChatMessage>> watchMessages(String matchId);
  Future<void> postRide(Ride ride, Student student);
  Future<RideMatch> joinOffer(
    String rideId,
    Student student, {
    String requestId = '',
  });
  Future<RideMatch> fulfilRequest(
    String requestId,
    String offerId,
    Student driver,
  );
  Future<void> cancelMatch(String matchId, Student student);
  Future<void> sendMessage(String matchId, Student student, String text);
  Future<void> resetDemo();
  void dispose();
}
