import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../domain/models.dart';
import 'theme.dart';
import 'screens/find_ride.dart';
import 'screens/post_ride.dart';
import 'screens/my_matches.dart';
import 'screens/login.dart';
import 'widgets/common.dart';
import 'widgets/community_panels.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(sessionProvider)
      .when(
        loading: () => const Scaffold(body: Center(child: Brand())),
        error: (e, _) => Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ErrorState(
                error: e,
                retry: () => ref.invalidate(sessionProvider),
              ),
            ),
          ),
        ),
        data: (student) {
          if (student == null) return const LoginScreen();
          if (!ref.watch(repositoryProvider).isDemo && !student.emailVerified) {
            return VerifyEmailScreen(student: student);
          }
          final tab = ref.watch(tabProvider);
          return LayoutBuilder(
            builder: (context, c) {
              final desktop = c.maxWidth >= 1024;
              return Scaffold(
                body: SafeArea(
                  child: Row(
                    children: [
                      if (desktop) const _Sidebar(),
                      Expanded(
                        child: Column(
                          children: [
                            _Header(student: student, desktop: desktop),
                            Expanded(
                              child: IndexedStack(
                                index: tab.index,
                                children: const [
                                  FindRideScreen(),
                                  PostRideScreen(),
                                  MyMatchesScreen(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: desktop
                    ? null
                    : NavigationBar(
                        selectedIndex: tab.index,
                        onDestinationSelected: (i) =>
                            ref.read(tabProvider.notifier).state =
                                AppTab.values[i],
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.search_rounded),
                            selectedIcon: Icon(Icons.search_rounded),
                            label: 'Find ride',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.add_circle_outline_rounded),
                            selectedIcon: Icon(Icons.add_circle_rounded),
                            label: 'Post ride',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.people_outline_rounded),
                            selectedIcon: Icon(Icons.people_rounded),
                            label: 'My matches',
                          ),
                        ],
                      ),
              );
            },
          );
        },
      );
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(tabProvider);
    final demo = ref.watch(repositoryProvider).isDemo;
    final count = (ref.watch(matchesProvider).valueOrNull ?? [])
        .where(
          (m) =>
              m.status == MatchStatus.confirmed &&
              m.departureAt.isAfter(DateTime.now()),
        )
        .length;
    return Container(
      width: 238,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Brand(),
          const SizedBox(height: 9),
          const Padding(
            padding: EdgeInsets.only(left: 48),
            child: Text(
              'YOUR CAMPUS, CONNECTED.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 7,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 43),
          const Padding(
            padding: EdgeInsets.only(left: 14, bottom: 15),
            child: Eyebrow('Your journey', color: AppColors.muted),
          ),
          ...AppTab.values.map((item) {
            final selected = tab == item;
            final label = [
              'Find a ride',
              'Post a ride',
              'My matches',
            ][item.index];
            final icon = [
              Icons.search_rounded,
              Icons.add_circle_outline_rounded,
              Icons.people_outline_rounded,
            ][item.index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: selected ? AppColors.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: ValueKey('nav_${item.name}'),
                  onTap: () => ref.read(tabProvider.notifier).state = item,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: selected ? Colors.white : AppColors.muted,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                        if (item == AppTab.matches && count > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withValues(alpha: .16)
                                  : AppColors.sage,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 9,
                                color: selected
                                    ? Colors.white
                                    : AppColors.green,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else if (selected)
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 17),
          TextButton.icon(
            onPressed: () => openPanel(context, const HowItWorksPanel()),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.muted,
              alignment: Alignment.centerLeft,
            ),
            icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
            label: const Text('How it works', style: TextStyle(fontSize: 11)),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.eco_outlined, size: 27, color: AppColors.green),
                SizedBox(height: 13),
                Text(
                  'Go together.\nGo better.',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: -.6,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Good company is just\na shared ride away.',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.circle, size: 6, color: AppColors.green),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  demo
                      ? 'Demo · saved on this device'
                      : 'Powered by Cloud Firestore',
                  style: const TextStyle(fontSize: 9, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            '© 2026 RideTogether',
            style: TextStyle(color: AppColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final Student student;
  final bool desktop;
  const _Header({required this.student, required this.desktop});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(repositoryProvider).isDemo;
    return Container(
      height: desktop ? 78 : 76,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 36 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          if (desktop)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => openPanel(context, const CampusPanel()),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.school_outlined, size: 18),
                  ),
                  const SizedBox(width: 11),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR CAMPUS',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 8,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Greenfield University',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
                ],
              ),
            )
          else
            Expanded(
              child: InkWell(
                onTap: () => openPanel(context, const CampusPanel()),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Brand(compact: true),
                ),
              ),
            ),
          if (desktop) const Spacer(),
          if (desktop) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                demo ? 'CAMPUS DEMO' : 'CAMPUS MEMBER',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 8,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 18),
          ],
          IconButton(
            tooltip: 'Your updates',
            onPressed: () =>
                openPanel(context, UpdatesPanel(hostContext: context)),
            icon: const Icon(Icons.notifications_none_rounded, size: 22),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Your profile',
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => openPanel(context, const ProfilePanel(), width: 450),
              child: Row(
                children: [
                  Avatar(
                    name: student.name,
                    asset: student.avatar,
                    size: desktop ? 36 : 34,
                  ),
                  if (desktop) ...[
                    const SizedBox(width: 9),
                    Text(
                      student.firstName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
