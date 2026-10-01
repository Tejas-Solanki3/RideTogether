import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'common.dart';
import 'route_map.dart';
import 'ride_panels.dart';

class ProfilePanel extends ConsumerWidget {
  const ProfilePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProvider);
    if (student == null) return const SizedBox();
    final demo = ref.watch(repositoryProvider).isDemo;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PanelHeader('Your campus profile'),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Avatar(name: student.name, asset: student.avatar, size: 76),
                  const SizedBox(height: 15),
                  Text(
                    student.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    student.email,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      demo ? 'SAMPLE STUDENT · LOCAL DEMO' : 'EMAIL VERIFIED',
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 1,
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Divider(),
            const SizedBox(height: 22),
            const DetailTile(
              icon: Icons.school_outlined,
              label: 'Campus',
              value: 'Greenfield University',
            ),
            const SizedBox(height: 23),
            Text(
              demo
                  ? 'Demo rides, connections, bookmarks and chat are saved in this browser or on this device. They are not shared with real students.'
                  : 'Your rides, matches and messages sync through Cloud Firestore. Only participants can access a connection and its chat.',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 26),
            if (demo)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Reset the local demo?'),
                        content: const Text(
                          'This removes your demo posts, connections, bookmarks and messages and restores the sample campus.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Keep my data'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Reset demo'),
                          ),
                        ],
                      ),
                    );
                    if (yes != true) return;
                    await ref.read(repositoryProvider).resetDemo();
                    await ref.read(savedRidesProvider.notifier).clear();
                    ref.read(rideFiltersProvider.notifier).state =
                        RideFilters.initial();
                    ref.read(tabProvider.notifier).state = AppTab.find;
                    if (context.mounted) {
                      Navigator.pop(context);
                      notify(
                        context,
                        'Fresh start. The sample campus is restored.',
                      );
                    }
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset local demo'),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(repositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CampusPanel extends StatelessWidget {
  const CampusPanel({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader('One campus. Many possibilities.'),
          const SizedBox(height: 8),
          const Eyebrow('Greenfield University · sample campus'),
          const SizedBox(height: 18),
          const RouteMap(
            originId: 'north_gate',
            destinationId: 'riverside_metro',
            height: 170,
          ),
          const SizedBox(height: 18),
          const Text(
            'Campus pickup points',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...CampusPlace.all.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 20,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          p.subtitle,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'These are sample locations, not real navigation data. Change CampusPlace.all and campusId to adapt the app to your university.',
            style: TextStyle(fontSize: 10, color: AppColors.muted, height: 1.8),
          ),
        ],
      ),
    ),
  );
}

class HowItWorksPanel extends StatelessWidget {
  const HowItWorksPanel({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader('Good rides, made simple.'),
          const SizedBox(height: 20),
          _step(
            '01',
            'Find your direction',
            'Choose your campus pickup, destination and date. Only compatible, future rides with enough seats appear.',
          ),
          _step(
            '02',
            'Make a connection',
            'Reserve a seat on an offer. Driving? Connect a request to your own compatible offer within 60 minutes.',
          ),
          _step(
            '03',
            'Say hello. Go together.',
            'Confirm pickup in your private match chat. Manage connections as a rider or driver in My matches.',
          ),
          const SizedBox(height: 8),
          Surface(
            color: AppColors.sage,
            padding: const EdgeInsets.all(18),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why these matches?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  'Exact, directional pickup and destination IDs avoid incorrect detours. Same-day matching avoids stale rides. Seat checks and atomic reservations prevent overbooking.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.green,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'RideTogether is a campus coordination prototype — not a taxi, payment, identity-check or emergency service. Wear seat belts and follow campus travel policies.',
            style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.8),
          ),
        ],
      ),
    ),
  );
  Widget _step(String n, String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 23),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              n,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.8,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class UpdatesPanel extends ConsumerWidget {
  final BuildContext hostContext;
  const UpdatesPanel({super.key, required this.hostContext});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentStudentProvider)?.id ?? '';
    final items = (ref.watch(matchesProvider).valueOrNull ?? [])
        .where((m) => m.status == MatchStatus.confirmed)
        .toList();
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PanelHeader('Your campus updates'),
            const SizedBox(height: 8),
            const Text(
              'In-app connection updates · no push notifications',
              style: TextStyle(color: AppColors.muted, fontSize: 10),
            ),
            const SizedBox(height: 18),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 26),
                child: Text(
                  'All quiet for now. Your new connections will appear here.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ...items.reversed
                .take(5)
                .map(
                  (m) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 7),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.handshake_outlined,
                        color: AppColors.green,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Connected with ${m.isDriver(uid) ? m.riderName : m.driverName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${m.origin.name} → ${m.destination.name}\n${dateLabel(m.departureAt)} · ${timeLabel(m.departureAt)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                        height: 1.8,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      openPanel(hostContext, ChatPanel(match: m), width: 560);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
