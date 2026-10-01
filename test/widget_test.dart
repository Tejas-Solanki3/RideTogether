import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ride_together/data/demo_repository.dart';
import 'package:ride_together/domain/models.dart';
import 'package:ride_together/main.dart';
import 'package:ride_together/state/providers.dart';

const capture = bool.fromEnvironment('CAPTURE_UI');
const previewBoundary = ValueKey('native_preview_boundary');
Future<DemoRideRepository> launch(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
  bool onboarded = true,
  bool signedIn = true,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  SharedPreferences.setMockInitialValues({'android_onboarding_v2': onboarded});
  final prefs = await SharedPreferences.getInstance();
  final repo = DemoRideRepository(prefs);
  if (signedIn) await repo.signIn(Student.demo.email, 'local-demo');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        preferencesProvider.overrideWithValue(prefs),
      ],
      child: const RepaintBoundary(
        key: previewBoundary,
        child: RideTogetherApp(),
      ),
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

Future<void> screenshot(WidgetTester tester, String name) async {
  if (!capture) return;
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(previewBoundary),
  );
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory('docs/screenshots')..createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
  });
  testWidgets(
    'first launch starts at welcome, never at an automatic demo session',
    (tester) async {
      final repo = await launch(tester, onboarded: false, signedIn: false);
      expect(await repo.watchSession().first, isNull);
      expect(find.text('Less solo.\nMore together.'), findsOneWidget);
      expect(find.text('Where to?'), findsNothing);
      await screenshot(tester, '01-welcome-android');
      await tester.drag(
        find.byKey(const ValueKey('get_started_slider')),
        const Offset(310, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Welcome\nback.'), findsOneWidget);
      expect(await repo.watchSession().first, isNull);
      await screenshot(tester, '02-login-android');
      await tapVisible(tester, find.text('Try the campus demo'));
      expect((await repo.watchSession().first)?.id, Student.demo.id);
      expect(find.text('Hello, Ishaan.\nWhere to?'), findsOneWidget);
    },
  );
  testWidgets('a short swipe resets without entering login', (tester) async {
    await launch(tester, onboarded: false, signedIn: false);
    await tester.drag(
      find.byKey(const ValueKey('get_started_slider')),
      const Offset(45, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Less solo.\nMore together.'), findsOneWidget);
    expect(find.text('Welcome\nback.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'login validates credentials instead of silently entering the app',
    (tester) async {
      await launch(tester, signedIn: false);
      await tapVisible(tester, find.text('Sign in').first);
      expect(find.text('Enter a valid campus email.'), findsOneWidget);
      expect(find.text('Use at least 6 characters.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('login_email')),
        Student.demo.email,
      );
      await tester.enterText(
        find.byKey(const ValueKey('login_password')),
        'demo123',
      );
      await tapVisible(tester, find.text('Sign in').first);
      expect(find.text('Hello, Ishaan.\nWhere to?'), findsOneWidget);
    },
  );
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
  ]) {
    testWidgets(
      'Android mobile and tablet navigation has no overflow at ${size.width.toInt()} px',
      (tester) async {
        await launch(tester, width: size.width, height: size.height);
        expect(find.text('Hello, Ishaan.\nWhere to?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final tab in ['post', 'matches', 'profile', 'find']) {
          await tester.tap(find.byKey(ValueKey('nav_$tab')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
  testWidgets(
    'rider reserves a seat, sends chat and cancels to restore capacity',
    (tester) async {
      final repo = await launch(tester);
      await screenshot(tester, '03-home-android');
      await tapVisible(tester, find.byKey(const ValueKey('home_search')));
      await screenshot(tester, '04-find-android');
      await tapVisible(tester, find.text('View ride').first);
      await screenshot(tester, '05-ride-details-android');
      await tapVisible(tester, find.text('Reserve 1 seat'));
      expect(find.text('You’re\nconnected.'), findsOneWidget);
      expect(
        (await repo.watchRides().first)
            .firstWhere((r) => r.id == 'offer_aarav')
            .availableSeats,
        2,
      );
      await screenshot(tester, '06-confirmation-android');
      await tapVisible(tester, find.text('Say hello in chat'));
      await tapVisible(tester, find.text('I’m at the pickup point'));
      final match = (await repo.watchMatches(Student.demo.id).first).firstWhere(
        (m) => m.offerId == 'offer_aarav',
      );
      expect(
        (await repo.watchMessages(match.id).first).last.text,
        'I’m at the pickup point.',
      );
      await screenshot(tester, '07-chat-android');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await screenshot(tester, '08-my-rides-android');
      await tapVisible(tester, find.text('Details').first);
      await tapVisible(tester, find.text('Cancel connection'));
      await tapVisible(tester, find.text('Cancel ride'));
      expect(
        (await repo.watchRides().first)
            .firstWhere((r) => r.id == 'offer_aarav')
            .availableSeats,
        3,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('three-step Android form validates and publishes an offer', (
    tester,
  ) async {
    final repo = await launch(tester);
    await tester.tap(find.byKey(const ValueKey('nav_post')));
    await tester.pumpAndSettle();
    await screenshot(tester, '09-post-route-android');
    await tapVisible(tester, find.text('Continue'));
    await tapVisible(tester, find.text('Continue'));
    expect(find.text('Add your vehicle model and colour.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('post_vehicle')),
      'Honda City · White',
    );
    await tapVisible(tester, find.byType(Checkbox));
    await screenshot(tester, '10-post-details-android');
    await tapVisible(tester, find.text('Continue'));
    await screenshot(tester, '11-post-review-android');
    await tapVisible(tester, find.text('Publish ride offer'));
    expect(find.text('Your ride\nis live.'), findsOneWidget);
    expect(
      (await repo.watchRides().first).any(
        (r) =>
            r.vehicle == 'Honda City · White' && r.ownerId == Student.demo.id,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'two-seat request context reserves both seats on a compatible offer',
    (tester) async {
      final repo = await launch(tester);
      await tester.tap(find.byKey(const ValueKey('nav_post')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I need a ride'));
      await tapVisible(tester, find.text('Continue'));
      await tester.tap(find.byTooltip('More seats'));
      await tapVisible(tester, find.byType(Checkbox));
      await tapVisible(tester, find.text('Continue'));
      await tapVisible(tester, find.text('Publish ride request'));
      await tapVisible(tester, find.text('Find compatible rides'));
      await tapVisible(tester, find.text('View ride').first);
      await tapVisible(tester, find.text('Reserve 2 seats'));
      expect(find.text('You’re\nconnected.'), findsOneWidget);
      final rides = await repo.watchRides().first;
      final request = rides.firstWhere(
        (r) => r.ownerId == Student.demo.id && r.kind == RideKind.request,
      );
      expect(request.active, isFalse);
      expect(request.matchedId, isNotEmpty);
      expect(rides.firstWhere((r) => r.id == 'offer_aarav').availableSeats, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('profile sign-out returns to login, not to the home screen', (
    tester,
  ) async {
    final repo = await launch(tester);
    await tester.tap(find.byKey(const ValueKey('nav_profile')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Sign out'));
    expect(await repo.watchSession().first, isNull);
    expect(find.text('Welcome\nback.'), findsOneWidget);
  });
}
