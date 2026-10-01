import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ride_together/data/demo_repository.dart';
import 'package:ride_together/domain/models.dart';
import 'package:ride_together/main.dart';
import 'package:ride_together/state/providers.dart';

Future<DemoRideRepository> launch(
  WidgetTester tester, {
  double width = 1440,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = DemoRideRepository(prefs);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        preferencesProvider.overrideWithValue(prefs),
      ],
      child: const RideTogetherApp(),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    repo.dispose();
  });
  return repo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
  });
  for (final width in [360.0, 390.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('responsive shell has no overflow at ${width.toInt()}px', (
      tester,
    ) async {
      await launch(tester, width: width);
      expect(find.text('Your campus.\nYour next ride.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final desktop = width >= 1024;
      await tester.tap(
        desktop
            ? find.byKey(const ValueKey('nav_post'))
            : find.text('Post ride'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(
        desktop
            ? find.byKey(const ValueKey('nav_matches'))
            : find.text('My matches'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('rider can find, connect, confirm, and see a match', (
    tester,
  ) async {
    final repo = await launch(tester);
    await tester.tap(find.text('View ride').first);
    await tester.pumpAndSettle();
    final connect = find.text('Connect & reserve 1 seat');
    await tester.ensureVisible(connect);
    await tester.tap(connect);
    await tester.pumpAndSettle();
    expect(find.text('Good company,\nconfirmed.'), findsOneWidget);
    expect(
      (await repo.watchRides().first)
          .firstWhere((r) => r.id == 'offer_aarav')
          .availableSeats,
      2,
    );
    await tester.ensureVisible(find.text('View my matches'));
    await tester.tap(find.text('View my matches'));
    await tester.pumpAndSettle();
    expect(find.text('Your rides. Your people.'), findsOneWidget);
    expect(find.text('Aarav Sharma'), findsOneWidget);
    expect(find.text('You’re riding'), findsOneWidget);
  });
  testWidgets(
    'guided post form validates vehicle, publishes a Ride, and exposes my posts',
    (tester) async {
      final repo = await launch(tester);
      await tester.tap(find.byKey(const ValueKey('nav_post')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Add your vehicle model and colour.'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Vehicle'),
        'Tata Nexon · Green',
      );
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Ready to go together?'), findsOneWidget);
      await tester.ensureVisible(find.text('Publish ride offer'));
      await tester.tap(find.text('Publish ride offer'));
      await tester.pumpAndSettle();
      expect(find.text('Your ride is live.'), findsOneWidget);
      expect(
        (await repo.watchRides().first).any(
          (r) => r.vehicle == 'Tata Nexon · Green' && r.kind == RideKind.offer,
        ),
        isTrue,
      );
      await tester.ensureVisible(find.text('View my posts'));
      await tester.tap(find.text('View my posts'));
      await tester.pumpAndSettle();
      expect(find.text('Tata Nexon · Green'), findsOneWidget);
    },
  );
  testWidgets(
    'mobile rider posts a two-seat request and connects it to a matching offer',
    (tester) async {
      final repo = await launch(tester, width: 390);
      await tester.tap(find.text('Post ride'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I need a ride'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More seats'));
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Publish ride request'));
      await tester.tap(find.text('Publish ride request'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Find compatible rides'));
      await tester.tap(find.text('Find compatible rides'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('View ride').first);
      await tester.tap(find.text('View ride').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Connect & reserve 2 seats'));
      await tester.tap(find.text('Connect & reserve 2 seats'));
      await tester.pumpAndSettle();
      expect(find.text('Good company,\nconfirmed.'), findsOneWidget);
      final request = (await repo.watchRides().first).firstWhere(
        (r) => r.ownerId == Student.demo.id && r.kind == RideKind.request,
      );
      expect(request.active, isFalse);
      expect(request.matchedId, isNotEmpty);
      expect(
        (await repo.watchRides().first)
            .firstWhere((r) => r.id == 'offer_aarav')
            .availableSeats,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
