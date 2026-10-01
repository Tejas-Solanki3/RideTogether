import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'widgets/common.dart';
import 'screens/onboarding.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/post_ride.dart';
import 'screens/my_matches.dart';
import 'screens/profile.dart';

/// Android-first shell: no desktop sidebar or browser landing page.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(onboardingProvider)) return const OnboardingScreen();
    final session = ref.watch(sessionProvider);
    if (session.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (session.hasError) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            'Couldn’t sign you in',
            friendlyError(session.error!),
            action: OutlinedButton(
              onPressed: () => ref.invalidate(sessionProvider),
              child: const Text('Try again'),
            ),
          ),
        ),
      );
    }
    final student = session.valueOrNull;
    if (student == null) return const LoginScreen();
    if (!ref.watch(repositoryProvider).isDemo && !student.emailVerified) {
      return const VerifyEmailScreen();
    }
    final tab = ref.watch(tabProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: IndexedStack(
              index: tab.index,
              children: const [
                HomeScreen(),
                PostRideScreen(),
                MyMatchesScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? const SizedBox()
          : const _BottomNav(),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  const _BottomNav();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(tabProvider);
    const tabs = [
      (AppTab.find, 'Home', 'house'),
      (AppTab.post, 'Post', 'plus'),
      (AppTab.matches, 'Rides', 'file-text'),
      (AppTab.profile, 'You', 'user-round'),
    ];
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 7, 16, 16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            height: 75,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE1E1E1),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFFD4D4D4)),
            ),
            child: Row(
              children: tabs.map((entry) {
                final active = selected == entry.$1;
                return Expanded(
                  flex: active ? 2 : 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Semantics(
                      selected: active,
                      button: true,
                      label: entry.$2,
                      child: Material(
                        color: active ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(35),
                        child: InkWell(
                          key: ValueKey('nav_${entry.$1.name}'),
                          borderRadius: BorderRadius.circular(35),
                          onTap: () =>
                              ref.read(tabProvider.notifier).state = entry.$1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 59,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppIcon(
                                  entry.$3,
                                  size: 22,
                                  color: active ? Colors.white : Colors.black,
                                ),
                                if (active) ...[
                                  const SizedBox(width: 9),
                                  Flexible(
                                    child: Text(
                                      entry.$2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
