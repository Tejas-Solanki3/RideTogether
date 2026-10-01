import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ride_card.dart';
import '../widgets/route_map.dart';
import '../widgets/ride_panels.dart';

class FindRideScreen extends ConsumerStatefulWidget {
  const FindRideScreen({super.key});
  @override
  ConsumerState<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends ConsumerState<FindRideScreen> {
  final _resultsKey = GlobalKey();
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(rideFiltersProvider);
    final matches = ref.watch(matchingRidesProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 650;
        final wide = constraints.maxWidth >= 990;
        final pad = mobile ? 20.0 : 36.0;
        return SingleChildScrollView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(pad, mobile ? 25 : 32, pad, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Hero(mobile: mobile),
                  const SizedBox(height: 28),
                  _RouteSearch(
                    onSearch: () {
                      if (filters.originId == filters.destinationId) {
                        notify(
                          context,
                          'Choose different pickup and destination points.',
                          error: true,
                        );
                        return;
                      }
                      Scrollable.ensureVisible(
                        _resultsKey.currentContext!,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        alignment: .08,
                      );
                    },
                  ),
                  const SizedBox(height: 31),
                  Row(
                    key: _resultsKey,
                    children: [
                      Expanded(
                        child: Text(
                          filters.savedOnly
                              ? 'Your saved rides'
                              : 'Rides heading your way',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const LiveDot(),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _FilterBar(),
                  const SizedBox(height: 17),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 13,
                                left: 2,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      matches.when(
                                        data: (r) =>
                                            '${r.length} compatible ${filters.kind == RideKind.offer ? 'rides' : 'requests'} · ${dateLabel(filters.date, long: true)}',
                                        loading: () =>
                                            'Finding your campus rides…',
                                        error: (_, __) => 'Campus rides',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<RideSort>(
                                    tooltip: 'Sort rides',
                                    initialValue: filters.sort,
                                    onSelected: (s) =>
                                        ref
                                            .read(rideFiltersProvider.notifier)
                                            .state = filters.copyWith(
                                          sort: s,
                                        ),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: RideSort.earliest,
                                        child: Text('Earliest departure'),
                                      ),
                                      PopupMenuItem(
                                        value: RideSort.lowestCost,
                                        child: Text('Lowest contribution'),
                                      ),
                                    ],
                                    child: Row(
                                      children: [
                                        Text(
                                          filters.sort == RideSort.earliest
                                              ? 'Earliest first'
                                              : 'Lowest cost',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            matches.when(
                              data: (rides) => rides.isEmpty
                                  ? EmptyState(
                                      title: filters.savedOnly
                                          ? 'Your next good ride is out there'
                                          : 'No rides on this route yet',
                                      subtitle: filters.savedOnly
                                          ? 'Save a ride using the bookmark icon. Saved rides still respect your route and date filters.'
                                          : 'Try another date or route, clear extra filters, or post a request so drivers can find you.',
                                      action: Column(
                                        children: [
                                          PrimaryButton(
                                            label: 'Post a ride request',
                                            onPressed: () {
                                              ref
                                                  .read(
                                                    postPrefillProvider
                                                        .notifier,
                                                  )
                                                  .state = Ride(
                                                id: 'prefill',
                                                ownerId: '',
                                                ownerName: '',
                                                ownerAvatar: '',
                                                originId: filters.originId,
                                                destinationId:
                                                    filters.destinationId,
                                                kind: RideKind.offer,
                                                departureAt: filters.date,
                                                createdAt: DateTime.now(),
                                                totalSeats: 1,
                                                availableSeats: 1,
                                              );
                                              ref
                                                  .read(tabProvider.notifier)
                                                  .state = AppTab
                                                  .post;
                                            },
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                ref
                                                        .read(
                                                          rideFiltersProvider
                                                              .notifier,
                                                        )
                                                        .state =
                                                    RideFilters.initial(),
                                            child: const Text(
                                              'Reset search filters',
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: rides.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 14),
                                      itemBuilder: (_, i) => RideCard(
                                        ride: rides[i],
                                        bestMatch:
                                            i == 0 &&
                                            filters.sort == RideSort.earliest,
                                        onView: () => openPanel(
                                          context,
                                          RideDetailsPanel(
                                            ride: rides[i],
                                            hostContext: context,
                                          ),
                                        ),
                                      ),
                                    ),
                              loading: () => const Surface(
                                child: SizedBox(
                                  height: 210,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              error: (e, _) => ErrorState(
                                error: e,
                                retry: () => ref.invalidate(ridesProvider),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 15,
                                  color: AppColors.muted,
                                ),
                                SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'Same campus. Same direction. Coordinate pickup in chat and travel responsibly.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (wide) ...[
                        const SizedBox(width: 23),
                        SizedBox(
                          width: 294,
                          child: _RouteAside(filters: filters),
                        ),
                      ],
                    ],
                  ),
                  if (!wide) ...[
                    const SizedBox(height: 26),
                    _RouteAside(filters: filters, compact: true),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  final bool mobile;
  const _Hero({required this.mobile});
  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('The campus commute, reimagined'),
        const SizedBox(height: 12),
        Text(
          'Your campus.\nYour next ride.',
          style: mobile
              ? Theme.of(context).textTheme.displayMedium
              : Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 13),
        const Text(
          'Skip the solo commute. Share a ride with\npeople heading your way.',
          style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.8),
        ),
        const SizedBox(height: 19),
        Row(
          children: [
            const SizedBox(
              width: 74,
              height: 31,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: Avatar(name: 'Aarav', asset: 'aarav', size: 31),
                  ),
                  Positioned(
                    left: 21,
                    child: Avatar(name: 'Ananya', asset: 'ananya', size: 31),
                  ),
                  Positioned(
                    left: 42,
                    child: Avatar(name: 'Rohan', asset: 'rohan', size: 31),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Your people. Your way.',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: SizedBox(
        height: mobile ? 190 : 244,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/campus_car.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(.45, .18),
            ),
            Positioned(
              left: 15,
              bottom: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .96),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_outlined, size: 15, color: AppColors.green),
                    SizedBox(width: 7),
                    Text(
                      'Better when we go together.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'THE EVERYDAY, UPGRADED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 22), image],
      );
    }
    return Row(
      children: [
        Expanded(flex: 11, child: title),
        const SizedBox(width: 24),
        Expanded(flex: 12, child: image),
      ],
    );
  }
}

class _RouteSearch extends ConsumerWidget {
  final VoidCallback onSearch;
  const _RouteSearch({required this.onSearch});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(rideFiltersProvider);
    Widget place(bool origin) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(origin ? 'Pickup point' : 'Where to?', color: AppColors.muted),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              origin ? Icons.trip_origin_rounded : Icons.square_rounded,
              size: 15,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: origin ? f.originId : f.destinationId,
                  isExpanded: true,
                  isDense: true,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  items: CampusPlace.all
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      ref.read(rideFiltersProvider.notifier).state = origin
                      ? f.copyWith(originId: v)
                      : f.copyWith(destinationId: v),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    final date = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final now = DateTime.now(),
            initial = f.date.isBefore(DateTime(now.year, now.month, now.day))
                ? now
                : f.date;
        final selected = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 365)),
        );
        if (selected != null) {
          ref.read(rideFiltersProvider.notifier).state = f.copyWith(
            date: selected,
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Departure', color: AppColors.muted),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 15),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    dateLabel(f.date, long: true),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
    final swap = IconButton(
      tooltip: 'Swap pickup and destination',
      onPressed: () => ref.read(rideFiltersProvider.notifier).state = f
          .copyWith(originId: f.destinationId, destinationId: f.originId),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.background,
        side: const BorderSide(color: AppColors.line),
      ),
      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
    );
    return Surface(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (_, c) {
          if (c.maxWidth < 720) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: place(true)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: swap,
                    ),
                    Expanded(child: place(false)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: date),
                    PrimaryButton(
                      label: 'Find rides',
                      icon: Icons.search_rounded,
                      arrow: false,
                      onPressed: onSearch,
                    ),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 5, child: place(true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: swap,
              ),
              Expanded(flex: 5, child: place(false)),
              Container(
                width: 1,
                height: 44,
                color: AppColors.line,
                margin: const EdgeInsets.symmetric(horizontal: 22),
              ),
              Expanded(flex: 4, child: date),
              const SizedBox(width: 15),
              PrimaryButton(
                label: 'Find rides',
                icon: Icons.search_rounded,
                arrow: false,
                onPressed: onSearch,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(rideFiltersProvider);
    final hasFilters =
        f.minimumSeats > 1 || f.freeOnly || f.timeMinutes != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SelectionPill(
            label: 'Ride offers',
            icon: Icons.drive_eta_outlined,
            selected: f.kind == RideKind.offer,
            onTap: () => ref.read(rideFiltersProvider.notifier).state = f
                .copyWith(kind: RideKind.offer),
          ),
          const SizedBox(width: 8),
          SelectionPill(
            label: 'Ride requests',
            icon: Icons.person_outline_rounded,
            selected: f.kind == RideKind.request,
            onTap: () => ref.read(rideFiltersProvider.notifier).state = f
                .copyWith(kind: RideKind.request),
          ),
          const SizedBox(width: 8),
          SelectionPill(
            label: 'Saved',
            icon: Icons.bookmark_border_rounded,
            selected: f.savedOnly,
            onTap: () => ref.read(rideFiltersProvider.notifier).state = f
                .copyWith(savedOnly: !f.savedOnly),
          ),
          const SizedBox(width: 8),
          SelectionPill(
            label: hasFilters ? 'Filters · On' : 'Filters',
            icon: Icons.tune_rounded,
            selected: hasFilters,
            onTap: () => openPanel(context, const _FilterPanel(), width: 440),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends ConsumerStatefulWidget {
  const _FilterPanel();
  @override
  ConsumerState<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<_FilterPanel> {
  late int seats;
  late bool free;
  int? minutes;
  @override
  void initState() {
    super.initState();
    final f = ref.read(rideFiltersProvider);
    seats = f.minimumSeats;
    free = f.freeOnly;
    minutes = f.timeMinutes;
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PanelHeader('Make it your ride'),
          const SizedBox(height: 20),
          const Text(
            'Minimum seats',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              6,
              (i) => SelectionPill(
                label: '${i + 1}',
                selected: seats == i + 1,
                onTap: () => setState(() => seats = i + 1),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Only free rides',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'No fuel contribution',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            value: free,
            activeTrackColor: AppColors.green,
            onChanged: (v) => setState(() => free = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'Preferred departure',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showTimePicker(
                context: context,
                initialTime: minutes == null
                    ? const TimeOfDay(hour: 17, minute: 30)
                    : TimeOfDay(hour: minutes! ~/ 60, minute: minutes! % 60),
              );
              if (selected != null) {
                setState(() => minutes = selected.hour * 60 + selected.minute);
              }
            },
            icon: const Icon(Icons.schedule, size: 17),
            label: Text(
              minutes == null
                  ? 'Any time'
                  : TimeOfDay(
                      hour: minutes! ~/ 60,
                      minute: minutes! % 60,
                    ).format(context),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We’ll include departures within 60 minutes of your preferred time.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Apply filters',
              onPressed: () {
                ref.read(rideFiltersProvider.notifier).state = ref
                    .read(rideFiltersProvider)
                    .copyWith(
                      minimumSeats: seats,
                      freeOnly: free,
                      timeMinutes: minutes,
                      clearTime: minutes == null,
                    );
                Navigator.pop(context);
              },
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                seats = 1;
                free = false;
                minutes = null;
              }),
              child: const Text('Reset extra filters'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RouteAside extends ConsumerWidget {
  final RideFilters filters;
  final bool compact;
  const _RouteAside({required this.filters, this.compact = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = Surface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Your route',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const Spacer(),
              const Text(
                'CAMPUS AREA',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          RouteMap(
            originId: filters.originId,
            destinationId: filters.destinationId,
            height: compact ? 205 : 224,
          ),
          const SizedBox(height: 12),
          const Text(
            'Illustrative campus map · not navigation',
            style: TextStyle(fontSize: 9, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.green,
              ),
              SizedBox(width: 7),
              Text(
                'Pickup made simple',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Meet at ${CampusPlace.byId(filters.originId).name}. Confirm the exact spot in chat before you leave.',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
    final nudge = Surface(
      color: AppColors.sage,
      padding: const EdgeInsets.all(23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_outlined, color: AppColors.green, size: 26),
          const SizedBox(height: 14),
          const Text(
            'A small ride.\nA big difference.',
            style: TextStyle(
              fontSize: 23,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Share the journey. Split the cost.\nKeep campus moving.',
            style: TextStyle(fontSize: 11, height: 1.8, color: AppColors.green),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ref.read(postPrefillProvider.notifier).state = null;
              ref.read(tabProvider.notifier).state = AppTab.post;
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.ink,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Offer a ride',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 14),
                Icon(Icons.arrow_forward_rounded, size: 17),
              ],
            ),
          ),
        ],
      ),
    );
    if (compact) {
      return LayoutBuilder(
        builder: (_, c) => c.maxWidth > 640
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: map),
                  const SizedBox(width: 18),
                  Expanded(child: nudge),
                ],
              )
            : map,
      );
    }
    return Column(children: [map, const SizedBox(height: 17), nudge]);
  }
}
