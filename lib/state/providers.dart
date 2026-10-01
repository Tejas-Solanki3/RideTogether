import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/ride_repository.dart';
import '../domain/matching.dart';
import '../domain/models.dart';

enum AppTab { find, post, matches, profile }

final repositoryProvider = Provider<RideRepository>(
  (ref) => throw UnimplementedError('Override in main'),
);
final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main'),
);
final sessionProvider = StreamProvider<Student?>(
  (ref) => ref.watch(repositoryProvider).watchSession(),
);
final currentStudentProvider = Provider<Student?>(
  (ref) => ref.watch(sessionProvider).valueOrNull,
);
final ridesProvider = StreamProvider<List<Ride>>((ref) {
  final student = ref.watch(currentStudentProvider);
  final repo = ref.watch(repositoryProvider);
  if (student == null || (!repo.isDemo && !student.emailVerified)) {
    return Stream.value([]);
  }
  return repo.watchRides();
});
final matchesProvider = StreamProvider<List<RideMatch>>((ref) {
  final student = ref.watch(currentStudentProvider);
  final repo = ref.watch(repositoryProvider);
  return student == null || (!repo.isDemo && !student.emailVerified)
      ? Stream.value([])
      : repo.watchMatches(student.id);
});
final messagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>(
      (ref, id) => ref.watch(repositoryProvider).watchMessages(id),
    );
final tabProvider = StateProvider<AppTab>((ref) => AppTab.find);
final rideFiltersProvider = StateProvider<RideFilters>(
  (ref) => RideFilters.initial(),
);
final postPrefillProvider = StateProvider<Ride?>((ref) => null);
final savedRidesProvider =
    StateNotifierProvider<SavedRidesNotifier, Set<String>>(
      (ref) => SavedRidesNotifier(ref.watch(preferencesProvider)),
    );

class SavedRidesNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences prefs;
  SavedRidesNotifier(this.prefs)
    : super((prefs.getStringList('saved_rides') ?? []).toSet());
  Future<void> toggle(String id) async {
    final next = Set<String>.of(state);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = next;
    await prefs.setStringList('saved_rides', next.toList());
  }

  Future<void> clear() async {
    state = {};
    await prefs.remove('saved_rides');
  }
}

final matchingRidesProvider = Provider<AsyncValue<List<Ride>>>((ref) {
  final filters = ref.watch(rideFiltersProvider);
  final uid = ref.watch(currentStudentProvider)?.id ?? '';
  final saved = ref.watch(savedRidesProvider);
  final now = ref.watch(clockProvider).valueOrNull ?? DateTime.now();
  return ref
      .watch(ridesProvider)
      .whenData(
        (rides) =>
            matchingRides(rides, filters, uid, savedIds: saved, now: now),
      );
});
final myPostsProvider = Provider<AsyncValue<List<Ride>>>((ref) {
  final uid = ref.watch(currentStudentProvider)?.id;
  return ref
      .watch(ridesProvider)
      .whenData(
        (rides) =>
            rides.where((r) => r.ownerId == uid).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
});

enum MatchesSection { upcoming, posts, past, cancelled }

final matchesSectionProvider = StateProvider<MatchesSection>(
  (ref) => MatchesSection.upcoming,
);

final requestContextProvider = StateProvider<String?>((ref) => null);
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

// First-launch UX is separate from authentication and never signs a student in.
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>(
  (ref) => OnboardingNotifier(ref.watch(preferencesProvider)),
);

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences prefs;
  OnboardingNotifier(this.prefs)
    : super(prefs.getBool('android_onboarding_v2') ?? false);
  Future<void> complete() async {
    if (!await prefs.setBool('android_onboarding_v2', true)) {
      throw const RideException(
        'Could not save your preference. Please try again.',
      );
    }
    state = true;
  }

  void showWelcome() => state = false;
}
