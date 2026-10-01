import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat.dart';
import 'find_ride.dart';
import 'ride_details.dart';

class MyMatchesScreen extends ConsumerStatefulWidget {
  const MyMatchesScreen({super.key});
  @override
  ConsumerState<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends ConsumerState<MyMatchesScreen> {
  bool? driverFilter;
  @override
  Widget build(BuildContext context) {
    final section = ref.watch(matchesSectionProvider),
        uid = ref.watch(currentStudentProvider)?.id ?? '';
    final all = ref.watch(matchesProvider);
    final posts = ref.watch(myPostsProvider);
    final now = ref.watch(clockProvider).valueOrNull ?? DateTime.now();
    final connections = (all.valueOrNull ?? []).where((m) {
      if (driverFilter != null && (m.driverId == uid) != driverFilter) {
        return false;
      }
      return switch (section) {
        MatchesSection.cancelled => m.status == MatchStatus.cancelled,
        MatchesSection.past =>
          m.status == MatchStatus.confirmed && !m.departureAt.isAfter(now),
        _ => m.status == MatchStatus.confirmed && m.departureAt.isAfter(now),
      };
    }).toList();
    final upcoming = (all.valueOrNull ?? [])
        .where(
          (m) =>
              m.status == MatchStatus.confirmed && m.departureAt.isAfter(now),
        )
        .length;
    return Column(
      children: [
        const PageHeader('My rides'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 19),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your rides.\nYour people.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Surface(
                color: Colors.black,
                radius: 18,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$upcoming',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Upcoming',
                      style: TextStyle(fontSize: 8, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _MainTab(
                  'Connections',
                  section != MatchesSection.posts,
                  () => ref.read(matchesSectionProvider.notifier).state =
                      MatchesSection.upcoming,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MainTab(
                  'My posts',
                  section == MatchesSection.posts,
                  () => ref.read(matchesSectionProvider.notifier).state =
                      MatchesSection.posts,
                ),
              ),
            ],
          ),
        ),
        if (section != MatchesSection.posts)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                ...[
                  (MatchesSection.upcoming, 'Upcoming'),
                  (MatchesSection.past, 'Past'),
                  (MatchesSection.cancelled, 'Cancelled'),
                ].map(
                  (entry) => Expanded(
                    child: InkWell(
                      onTap: () =>
                          ref.read(matchesSectionProvider.notifier).state =
                              entry.$1,
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 11, top: 7),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: section == entry.$1
                                  ? Colors.black
                                  : AppColors.line,
                              width: section == entry.$1 ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          entry.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: section == entry.$1
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: section == entry.$1
                                ? Colors.black
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (section != MatchesSection.posts)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${connections.length} ${connections.length == 1 ? 'connection' : 'connections'}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                PopupMenuButton<int>(
                  tooltip: 'Filter by your role',
                  onSelected: (v) =>
                      setState(() => driverFilter = v == 0 ? null : v == 1),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0, child: Text('All roles')),
                    PopupMenuItem(value: 1, child: Text('I’m driving')),
                    PopupMenuItem(value: 2, child: Text('I’m riding')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        Text(
                          driverFilter == null
                              ? 'All roles'
                              : driverFilter!
                              ? 'Driving'
                              : 'Riding',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const AppIcon('chevron-down', size: 13),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: section == MatchesSection.posts
              ? posts.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, s) =>
                      EmptyState('Couldn’t load posts', friendlyError(e)),
                  data: (list) => list.isEmpty
                      ? _empty(true)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, i) => _Post(list[i]),
                        ),
                )
              : all.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, s) =>
                      EmptyState('Couldn’t load connections', friendlyError(e)),
                  data: (_) => connections.isEmpty
                      ? _empty(false)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: connections.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 16),
                          itemBuilder: (_, i) =>
                              _Connection(connections[i], uid: uid),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _empty(bool posts) => ListView(
    children: [
      EmptyState(
        posts ? 'No posts yet.' : 'No connections here yet.',
        posts
            ? 'Offer a seat or ask for a lift. Your posts will live here.'
            : 'Find a ride heading your way. Confirmed connections appear here.',
        icon: posts ? 'file-text' : 'route',
        action: OutlinedButton(
          onPressed: () => ref.read(tabProvider.notifier).state = posts
              ? AppTab.post
              : AppTab.find,
          child: Text(posts ? 'Post a ride' : 'Find a ride'),
        ),
      ),
    ],
  );
}

class _MainTab extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback tap;
  const _MainTab(this.text, this.active, this.tap);
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: tap,
    style: FilledButton.styleFrom(
      backgroundColor: active ? Colors.black : const Color(0xFFE8E8E8),
      foregroundColor: active ? Colors.white : Colors.black,
      minimumSize: const Size(0, 49),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );
}

class _Connection extends StatelessWidget {
  final RideMatch m;
  final String uid;
  const _Connection(this.m, {required this.uid});
  @override
  Widget build(BuildContext context) {
    final driver = m.driverId == uid;
    final cancelled = m.status == MatchStatus.cancelled;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(
                  name: driver ? m.riderName : m.driverName,
                  asset: driver ? m.riderAvatar : m.driverAvatar,
                  size: 41,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver ? m.riderName : m.driverName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cancelled
                            ? 'Cancelled connection'
                            : driver
                            ? 'Your rider'
                            : 'Your driver',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                RoleBadge(driver: driver, label: driver ? 'Driving' : 'Riding'),
              ],
            ),
            const SizedBox(height: 18),
            RouteSummary(originId: m.originId, destinationId: m.destinationId),
            const SizedBox(height: 13),
            DetailRow(
              'Date & time',
              '${dateLabel(m.departureAt)} · ${timeLabel(m.departureAt)}',
            ),
            DetailRow('Reserved seats', '${m.seats}'),
            DetailRow('Vehicle', m.vehicle),
            const Divider(height: 21),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MatchDetailsScreen(match: m),
                      ),
                    ),
                    child: const Text(
                      'Details',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatScreen(match: m),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          'message-circle',
                          size: 17,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text('Chat', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Post extends ConsumerWidget {
  final Ride r;
  const _Post(this.r);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = r.kind == RideKind.offer;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RoleBadge(
                driver: offer,
                label: offer ? 'Your offer' : 'Your request',
              ),
              const Spacer(),
              Text(
                !r.active
                    ? 'Matched'
                    : r.departureAt.isAfter(DateTime.now())
                    ? 'Active'
                    : 'Past',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          RouteSummary(originId: r.originId, destinationId: r.destinationId),
          const SizedBox(height: 13),
          DetailRow(
            'Date & time',
            '${dateLabel(r.departureAt)} · ${timeLabel(r.departureAt)}',
          ),
          DetailRow(
            offer ? 'Seats available' : 'Requested seats',
            offer
                ? '${r.availableSeats} of ${r.totalSeats}'
                : '${r.totalSeats}',
          ),
          if (offer) DetailRow('Vehicle', r.vehicle),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RideDetailsScreen(rideId: r.id),
                ),
              ),
              child: const Text('View details'),
            ),
          ),
          if (!offer && r.active && r.departureAt.isAfter(DateTime.now()))
            TextButton(
              onPressed: () {
                ref.read(requestContextProvider.notifier).state = r.id;
                ref.read(rideFiltersProvider.notifier).state = RideFilters(
                  originId: r.originId,
                  destinationId: r.destinationId,
                  date: r.departureAt,
                  minimumSeats: r.totalSeats,
                  timeMinutes: r.departureAt.hour * 60 + r.departureAt.minute,
                );
                ref.read(tabProvider.notifier).state = AppTab.find;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FindRideScreen(),
                  ),
                );
              },
              child: const Text('Find compatible drivers'),
            ),
        ],
      ),
    );
  }
}
