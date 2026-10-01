import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ride_panels.dart';

class MyMatchesScreen extends ConsumerStatefulWidget {
  const MyMatchesScreen({super.key});
  @override
  ConsumerState<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends ConsumerState<MyMatchesScreen> {
  String role = 'All rides';
  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProvider);
    final data = ref.watch(matchesProvider), posts = ref.watch(myPostsProvider);
    final section = ref.watch(matchesSectionProvider);
    final all = data.valueOrNull ?? [], ownPosts = posts.valueOrNull ?? [];
    final now = ref.watch(clockProvider).valueOrNull ?? DateTime.now();
    final upcoming = all
        .where(
          (m) =>
              m.status == MatchStatus.confirmed && m.departureAt.isAfter(now),
        )
        .toList();
    final seatsShared = all
        .where(
          (m) => m.status == MatchStatus.confirmed && m.driverId == student?.id,
        )
        .fold<int>(0, (n, m) => n + m.seats);
    final cancelled = all
        .where((m) => m.status == MatchStatus.cancelled)
        .toList();
    final past = all
        .where(
          (m) =>
              m.status == MatchStatus.confirmed && !m.departureAt.isAfter(now),
        )
        .toList();
    final list = switch (section) {
      MatchesSection.upcoming => upcoming,
      MatchesSection.past => past,
      MatchesSection.cancelled => cancelled,
      _ => <RideMatch>[],
    };
    final filtered = list
        .where(
          (m) =>
              role == 'All rides' ||
              (role == 'As a driver'
                  ? m.isDriver(student?.id ?? '')
                  : !m.isDriver(student?.id ?? '')),
        )
        .toList();
    return LayoutBuilder(
      builder: (context, c) {
        final mobile = c.maxWidth < 650;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            mobile ? 20 : 36,
            31,
            mobile ? 20 : 36,
            40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Your campus connections'),
                  const SizedBox(height: 11),
                  Text(
                    'Your rides. Your people.',
                    style: mobile
                        ? Theme.of(context).textTheme.headlineMedium
                        : Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'From the first hello to the last drop-off, it’s all here.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 27),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          icon: Icons.route_outlined,
                          value: '${upcoming.length}',
                          label: 'Upcoming rides',
                          dark: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Stat(
                          icon: Icons.airline_seat_recline_normal,
                          value: '$seatsShared',
                          label: 'Seats shared',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Stat(
                          icon: Icons.edit_note_outlined,
                          value: '${ownPosts.length}',
                          label: 'Your posts',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 27),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SelectionPill(
                          label: 'Upcoming · ${upcoming.length}',
                          selected: section == MatchesSection.upcoming,
                          onTap: () =>
                              ref.read(matchesSectionProvider.notifier).state =
                                  MatchesSection.upcoming,
                        ),
                        const SizedBox(width: 8),
                        SelectionPill(
                          label: 'My posts · ${ownPosts.length}',
                          selected: section == MatchesSection.posts,
                          onTap: () =>
                              ref.read(matchesSectionProvider.notifier).state =
                                  MatchesSection.posts,
                        ),
                        const SizedBox(width: 8),
                        SelectionPill(
                          label: 'Past',
                          selected: section == MatchesSection.past,
                          onTap: () =>
                              ref.read(matchesSectionProvider.notifier).state =
                                  MatchesSection.past,
                        ),
                        const SizedBox(width: 8),
                        SelectionPill(
                          label: 'Cancelled',
                          selected: section == MatchesSection.cancelled,
                          onTap: () =>
                              ref.read(matchesSectionProvider.notifier).state =
                                  MatchesSection.cancelled,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          section == MatchesSection.posts
                              ? 'Rides you’ve posted'
                              : 'Your ${section.name} connections',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (section != MatchesSection.posts)
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: role,
                            isDense: true,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                            items: ['All rides', 'As a rider', 'As a driver']
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: (r) => setState(() => role = r!),
                          ),
                        )
                      else
                        const LiveDot(),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (section == MatchesSection.posts)
                    posts.when(
                      data: (_) => ownPosts.isEmpty
                          ? _empty(
                              'Your first shared ride starts here.',
                              'Post an offer or request and let your campus find you.',
                              post: true,
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: ownPosts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (_, i) =>
                                  _PostCard(ride: ownPosts[i]),
                            ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => ErrorState(
                        error: e,
                        retry: () => ref.invalidate(ridesProvider),
                      ),
                    )
                  else
                    data.when(
                      data: (_) => filtered.isEmpty
                          ? _empty(
                              section == MatchesSection.upcoming
                                  ? 'Your next connection is waiting.'
                                  : 'Nothing here just yet.',
                              section == MatchesSection.upcoming
                                  ? 'Find a ride on your route, reserve a seat, and say hello. Your connections will appear here.'
                                  : 'Your ${section.name} connections will be listed here. Try another ride role if a filter is active.',
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 15),
                              itemBuilder: (_, i) =>
                                  _MatchCard(match: filtered[i]),
                            ),
                      loading: () => const Surface(
                        child: SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (e, _) => ErrorState(
                        error: e,
                        retry: () => ref.invalidate(matchesProvider),
                      ),
                    ),
                  const SizedBox(height: 25),
                  Surface(
                    color: AppColors.sage,
                    padding: const EdgeInsets.all(21),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.green,
                          size: 23,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A quick hello makes a smooth pickup.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Confirm the exact meeting spot in chat. If your plans change, cancel before departure — seats return to the offer automatically.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.green,
                                  height: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _empty(String title, String subtitle, {bool post = false}) =>
      EmptyState(
        title: title,
        subtitle: subtitle,
        icon: Icons.handshake_outlined,
        action: PrimaryButton(
          label: post ? 'Post a ride' : 'Find a ride',
          onPressed: () => ref.read(tabProvider.notifier).state = post
              ? AppTab.post
              : AppTab.find,
        ),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final bool dark;
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.dark = false,
  });
  @override
  Widget build(BuildContext context) => Surface(
    color: dark ? AppColors.ink : Colors.white,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: dark ? const Color(0xFFB6D6A9) : AppColors.green,
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            color: dark ? Colors.white : AppColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: dark ? Colors.white.withValues(alpha: .65) : AppColors.muted,
          ),
        ),
      ],
    ),
  );
}

class _MatchCard extends ConsumerWidget {
  final RideMatch match;
  const _MatchCard({required this.match});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = match.isDriver(ref.watch(currentStudentProvider)?.id ?? '');
    final cancelled = match.status == MatchStatus.cancelled;
    final offer = (ref.watch(ridesProvider).valueOrNull ?? [])
        .where((r) => r.id == match.offerId)
        .firstOrNull;
    return Surface(
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, c) {
          final small = c.maxWidth < 550;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(
                    name: driver ? match.riderName : match.driverName,
                    asset: driver ? match.riderAvatar : match.driverAvatar,
                    size: 43,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver ? match.riderName : match.driverName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          driver
                              ? 'Your travel partner · Rider'
                              : match.vehicle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!small)
                    RoleBadge(
                      driver: driver,
                      label: driver ? 'You’re driving' : 'You’re riding',
                    ),
                ],
              ),
              if (small) ...[
                const SizedBox(height: 12),
                RoleBadge(
                  driver: driver,
                  label: driver ? 'You’re driving' : 'You’re riding',
                ),
              ],
              const SizedBox(height: 22),
              RouteRow(
                origin: match.origin,
                destination: match.destination,
                vertical: small,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 18,
                runSpacing: 9,
                children: [
                  InfoItem(
                    Icons.calendar_today_outlined,
                    dateLabel(match.departureAt, long: true),
                  ),
                  InfoItem(
                    Icons.schedule_rounded,
                    timeLabel(match.departureAt),
                  ),
                  InfoItem(
                    Icons.airline_seat_recline_normal,
                    '${match.seats} ${cancelled ? 'released' : 'reserved'}',
                    color: cancelled ? AppColors.red : AppColors.green,
                  ),
                  if (driver && offer != null && !cancelled)
                    InfoItem(
                      Icons.event_seat_outlined,
                      '${offer.availableSeats} still open',
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: cancelled ? AppColors.red : AppColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cancelled
                              ? 'Cancelled'
                              : match.departureAt.isAfter(DateTime.now())
                              ? 'Connected'
                              : 'Past ride',
                          style: TextStyle(
                            fontSize: 10,
                            color: cancelled ? AppColors.red : AppColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => openPanel(
                      context,
                      MatchDetailsPanel(match: match, hostContext: context),
                    ),
                    child: const Text('Details'),
                  ),
                  if (!cancelled) ...[
                    const SizedBox(width: 9),
                    PrimaryButton(
                      label: 'Chat',
                      icon: Icons.chat_bubble_outline_rounded,
                      arrow: false,
                      onPressed: () => openPanel(
                        context,
                        ChatPanel(match: match),
                        width: 560,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final Ride ride;
  const _PostCard({required this.ride});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = ride.kind == RideKind.offer,
        past = !ride.departureAt.isAfter(DateTime.now());
    return Surface(
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RoleBadge(
                  driver: driver,
                  label: driver ? 'Your ride offer' : 'Your ride request',
                ),
                const Spacer(),
                Text(
                  past
                      ? 'Departed'
                      : !ride.active
                      ? 'Matched'
                      : ride.availableSeats == 0
                      ? 'Full'
                      : 'Open',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            RouteRow(
              origin: ride.origin,
              destination: ride.destination,
              vertical: c.maxWidth < 470,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 18,
              runSpacing: 9,
              children: [
                InfoItem(
                  Icons.calendar_today_outlined,
                  dateLabel(ride.departureAt, long: true),
                ),
                InfoItem(Icons.schedule, timeLabel(ride.departureAt)),
                InfoItem(
                  Icons.airline_seat_recline_normal,
                  driver
                      ? '${ride.availableSeats} / ${ride.totalSeats} seats available'
                      : '${ride.totalSeats} seats needed',
                ),
                InfoItem(
                  Icons.payments_outlined,
                  '₹${ride.contribution} / seat',
                ),
              ],
            ),
            if (driver) ...[
              const SizedBox(height: 14),
              Text(
                ride.vehicle,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
            const SizedBox(height: 19),
            const Divider(),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: PrimaryButton(
                label: driver
                    ? 'Find compatible riders'
                    : 'Find compatible drivers',
                onPressed: past || !ride.active || ride.availableSeats == 0
                    ? null
                    : () {
                        ref
                            .read(rideFiltersProvider.notifier)
                            .state = RideFilters(
                          originId: ride.originId,
                          destinationId: ride.destinationId,
                          date: ride.departureAt,
                          kind: driver ? RideKind.request : RideKind.offer,
                          minimumSeats: driver ? 1 : ride.totalSeats,
                          timeMinutes:
                              ride.departureAt.hour * 60 +
                              ride.departureAt.minute,
                        );
                        ref.read(requestContextProvider.notifier).state = driver
                            ? null
                            : ride.id;
                        ref.read(tabProvider.notifier).state = AppTab.find;
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
