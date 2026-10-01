import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ride_card.dart';
import 'home.dart';

class FindRideScreen extends ConsumerWidget {
  const FindRideScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(rideFiltersProvider),
        results = ref.watch(matchingRidesProvider);
    final contextId = ref.watch(requestContextProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              'Find a ride',
              back: () => Navigator.pop(context),
              trailing: RoundButton(
                'sliders-horizontal',
                label: 'Ride filters',
                onPressed: () => _filters(context, ref),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 17),
              child: Surface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                radius: 18,
                child: Row(
                  children: [
                    const AppIcon('route', size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${CampusPlace.byId(f.originId).name} →',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            CampusPlace.byId(f.destinationId).name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final d = await pickCampusDate(context, f.date);
                        if (d != null) {
                          ref.read(rideFiltersProvider.notifier).state = f
                              .copyWith(date: d);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dateLabel(f.date),
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 6),
                          const AppIcon('chevron-down', size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _Type(
                      'Ride offers',
                      f.kind == RideKind.offer,
                      () => ref.read(rideFiltersProvider.notifier).state = f
                          .copyWith(kind: RideKind.offer),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Type(
                      'Ride requests',
                      f.kind == RideKind.request,
                      () => ref.read(rideFiltersProvider.notifier).state = f
                          .copyWith(kind: RideKind.request),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Saved rides only',
                    onPressed: () =>
                        ref.read(rideFiltersProvider.notifier).state = f
                            .copyWith(savedOnly: !f.savedOnly),
                    icon: AppIcon(
                      'bookmark',
                      size: 19,
                      color: f.savedOnly ? Colors.white : Colors.black,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: f.savedOnly
                          ? Colors.black
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                ],
              ),
            ),
            if (contextId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Surface(
                  color: Colors.black,
                  radius: 15,
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  child: Row(
                    children: [
                      const AppIcon(
                        'users-round',
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Connecting your posted request',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Book just for yourself',
                        onPressed: () =>
                            ref.read(requestContextProvider.notifier).state =
                                null,
                        icon: const AppIcon('x', size: 17, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: results.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, s) => EmptyState(
                  'Couldn’t load rides',
                  friendlyError(e),
                  action: OutlinedButton(
                    onPressed: () => ref.invalidate(ridesProvider),
                    child: const Text('Try again'),
                  ),
                ),
                data: (rides) => ListView.separated(
                  key: const PageStorageKey('find_results'),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: rides.isEmpty ? 1 : rides.length + 1,
                  separatorBuilder: (_, i) => const SizedBox(height: 16),
                  itemBuilder: (ctx, i) {
                    if (rides.isEmpty) {
                      return EmptyState(
                        'No rides on this route yet.',
                        'Try another date or post a request.\nWe match the same route and day.',
                        action: OutlinedButton(
                          onPressed: () {
                            ref.read(tabProvider.notifier).state = AppTab.post;
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                          child: const Text('Post a ride'),
                        ),
                      );
                    }
                    if (i == 0) {
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${rides.length} ${rides.length == 1 ? 'match' : 'matches'} · live availability',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          PopupMenuButton<RideSort>(
                            tooltip: 'Sort rides',
                            initialValue: f.sort,
                            onSelected: (v) =>
                                ref.read(rideFiltersProvider.notifier).state = f
                                    .copyWith(sort: v),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: RideSort.earliest,
                                child: Text('Earliest first'),
                              ),
                              PopupMenuItem(
                                value: RideSort.lowestCost,
                                child: Text('Lowest contribution'),
                              ),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    f.sort == RideSort.earliest
                                        ? 'Earliest first'
                                        : 'Lowest cost',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const AppIcon('chevron-down', size: 13),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return RideCard(rides[i - 1]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filters(BuildContext context, WidgetRef ref) {
    final original = ref.read(rideFiltersProvider);
    int seats = original.minimumSeats;
    bool free = original.freeOnly;
    int? minutes = original.timeMinutes;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Make it your ride.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Minimum available seats',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fewer seats',
                    onPressed: seats > 1 ? () => set(() => seats--) : null,
                    icon: const AppIcon('minus', size: 19),
                  ),
                  Text(
                    '$seats',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    tooltip: 'More seats',
                    onPressed: seats < 6 ? () => set(() => seats++) : null,
                    icon: const AppIcon('plus', size: 19),
                  ),
                ],
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Free rides only',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'No suggested fuel contribution',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                value: free,
                onChanged: (v) => set(() => free = v),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AppIcon('clock-3'),
                title: const Text(
                  'Preferred time',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  minutes == null
                      ? 'Any time · or choose a ±60 min window'
                      : TimeOfDay(
                          hour: minutes! ~/ 60,
                          minute: minutes! % 60,
                        ).format(context),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                trailing: minutes == null
                    ? const AppIcon('chevron-down', size: 18)
                    : IconButton(
                        tooltip: 'Clear time filter',
                        onPressed: () => set(() => minutes = null),
                        icon: const AppIcon('x', size: 18),
                      ),
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                  );
                  if (t != null) set(() => minutes = t.hour * 60 + t.minute);
                },
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                'Show matching rides',
                onPressed: () {
                  ref.read(rideFiltersProvider.notifier).state = original
                      .copyWith(
                        minimumSeats: seats,
                        freeOnly: free,
                        timeMinutes: minutes,
                        clearTime: minutes == null,
                      );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Type extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback tap;
  const _Type(this.label, this.active, this.tap);
  @override
  Widget build(BuildContext context) => Material(
    color: active ? Colors.black : Colors.white,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : Colors.black,
          ),
        ),
      ),
    ),
  );
}
