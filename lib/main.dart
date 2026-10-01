import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/firebase_config.dart';
import 'data/demo_repository.dart';
import 'data/firestore_repository.dart';
import 'data/ride_repository.dart';
import 'state/providers.dart';
import 'ui/theme.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  try {
    final prefs = await SharedPreferences.getInstance();
    final RideRepository repository;
    if (FirebaseConfig.enabled) {
      await Firebase.initializeApp(options: FirebaseConfig.options);
      repository = FirestoreRideRepository(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
      );
    } else {
      repository = DemoRideRepository(prefs);
    }
    runApp(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          preferencesProvider.overrideWithValue(prefs),
        ],
        child: const RideTogetherApp(),
      ),
    );
  } catch (error) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings_outlined, size: 40),
                  const SizedBox(height: 20),
                  const Text(
                    'A little setup is needed',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text('$error', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  const Text(
                    'See docs/FIREBASE_SETUP.md. Run without USE_FIREBASE to try the local demo.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RideTogetherApp extends StatelessWidget {
  const RideTogetherApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RideTogether',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    builder: (context, child) => ColoredBox(
      color: const Color(0xFFE9E9E9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child ?? const SizedBox(),
        ),
      ),
    ),
    home: const AppShell(),
    scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
  );
}
