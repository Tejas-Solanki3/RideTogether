import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/route_map.dart';
import 'find_ride.dart';

Future<DateTime?> pickCampusDate(BuildContext context, DateTime selected) {
  final today = DateUtils.dateOnly(DateTime.now());
  final initial = DateUtils.dateOnly(selected).isBefore(today)
      ? today
      : DateUtils.dateOnly(selected);
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: today,
    lastDate: today.add(const Duration(days: 365)),
    helpText: 'When are you leaving?',
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProvider);
    if (student == null) return const SizedBox();
    final f = ref.watch(rideFiltersProvider),
        driving = f.kind == RideKind.request;
    void update(RideFilters value) {
      ref.read(rideFiltersProvider.notifier).state = value;
      ref.read(requestContextProvider.notifier).state = null;
    }

    Future<void> place(bool origin) async {
      final value = await choosePlace(
        context,
        title: origin ? 'Where from?' : 'Where to?',
        selected: origin ? f.originId : f.destinationId,
      );
      if (value != null) {
        update(
          origin
              ? f.copyWith(originId: value)
              : f.copyWith(destinationId: value),
        );
      }
    }

    return ListView(
      key: const PageStorageKey('home_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () =>
                  ref.read(tabProvider.notifier).state = AppTab.profile,
              child: Avatar(
                name: student.name,
                asset: student.avatar,
                size: 47,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'GREENFIELD UNIVERSITY',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.muted,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            RoundButton(
              'bell',
              label: 'Your updates',
              onPressed: () => _updates(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Hello, ${student.firstName}.\nWhere to?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 30,
            letterSpacing: -1.15,
          ),
        ),
        const SizedBox(height: 23),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => place(false),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 10, 10, 10),
              child: Row(
                children: [
                  const AppIcon('search', size: 23),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Enter destination',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  SizedBox(
                    width: 75,
                    child: RouteMap(
                      originId: f.originId,
                      destinationId: f.destinationId,
                      height: 42,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _Mode(
                'I’m riding',
                'Find a campus lift',
                'user-round',
                !driving,
                () => update(f.copyWith(kind: RideKind.offer)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Mode(
                'I’m driving',
                'Offer a spare seat',
                'car-front',
                driving,
                () => update(f.copyWith(kind: RideKind.request)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 23),
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectTile(
                    key: const ValueKey('home_origin'),
                    label: 'From',
                    value: CampusPlace.byId(f.originId).name,
                    subtitle: 'Campus pickup',
                    icon: 'navigation',
                    onTap: () => place(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SelectTile(
                    key: const ValueKey('home_destination'),
                    label: 'To',
                    value: CampusPlace.byId(f.destinationId).name,
                    subtitle: 'Your drop-off',
                    icon: 'map-pin',
                    onTap: () => place(false),
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.line),
              ),
              child: IconButton(
                tooltip: 'Swap route',
                onPressed: () => update(
                  f.copyWith(
                    originId: f.destinationId,
                    destinationId: f.originId,
                  ),
                ),
                icon: const AppIcon('arrow-up-down', size: 18),
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(minWidth: 43, minHeight: 43),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SelectTile(
                label: 'Departing on',
                value: dateLabel(f.date),
                icon: 'calendar-days',
                onTap: () async {
                  final d = await pickCampusDate(context, f.date);
                  if (d != null) update(f.copyWith(date: d));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SelectTile(
                label: driving ? 'Minimum seats' : 'Passengers',
                value:
                    '${f.minimumSeats} ${f.minimumSeats == 1 ? 'passenger' : 'passengers'}',
                icon: 'users-round',
                onTap: () async {
                  final seats = await showModalBottomSheet<int>(
                    context: context,
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How many seats?',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(
                              6,
                              (i) => SizedBox(
                                width: 48,
                                height: 48,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: f.minimumSeats == i + 1
                                        ? Colors.black
                                        : AppColors.surface,
                                    foregroundColor: f.minimumSeats == i + 1
                                        ? Colors.white
                                        : Colors.black,
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, i + 1),
                                  child: Text('${i + 1}'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (seats != null) update(f.copyWith(minimumSeats: seats));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          driving ? 'Find riders' : 'Find a ride',
          key: const ValueKey('home_search'),
          onPressed: () {
            if (f.originId == f.destinationId) {
              notify(context, 'Choose a different destination.');
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FindRideScreen()),
            );
          },
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
              child: Text(
                'A little more together.',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(tabProvider.notifier).state = AppTab.post,
              child: const Text('Post a ride'),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: SizedBox(
            height: 174,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/welcome_car.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, .6),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xEE000000), Color(0x33000000)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                const Positioned(
                  left: 20,
                  top: 22,
                  child: Text(
                    'Every seat\ncounts.',
                    style: TextStyle(
                      fontSize: 27,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Positioned(
                  left: 20,
                  bottom: 19,
                  child: Text(
                    'Same campus. Better company.',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (ref.watch(repositoryProvider).isDemo)
          const Center(
            child: Text(
              'LOCAL CAMPUS DEMO · SAVED ON THIS DEVICE',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 1,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  void _updates(BuildContext context, WidgetRef ref) {
    final list = ref.read(matchesProvider).valueOrNull ?? [];
    final upcoming = list
        .where(
          (m) =>
              m.status == MatchStatus.confirmed &&
              m.departureAt.isAfter(DateTime.now()),
        )
        .toList();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your updates',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text(
              upcoming.isEmpty
                  ? 'You’re all caught up. New connections will appear here.'
                  : '${upcoming.length} upcoming connection${upcoming.length == 1 ? '' : 's'}. Check your rides to confirm pickup details.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              'View my rides',
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(tabProvider.notifier).state = AppTab.matches;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Mode extends StatelessWidget {
  final String title, subtitle, icon;
  final bool selected;
  final VoidCallback tap;
  const _Mode(this.title, this.subtitle, this.icon, this.selected, this.tap);
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? Colors.black : Colors.white,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(19),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            AppIcon(
              icon,
              color: selected ? Colors.white : Colors.black,
              size: 23,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8,
                      color: selected
                          ? const Color(0xFFDDDDDD)
                          : AppColors.muted,
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
}
