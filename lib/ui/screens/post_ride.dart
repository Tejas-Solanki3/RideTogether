import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'find_ride.dart';
import 'home.dart';

class PostRideScreen extends ConsumerStatefulWidget {
  const PostRideScreen({super.key});
  @override
  ConsumerState<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends ConsumerState<PostRideScreen> {
  final form = GlobalKey<FormState>();
  final vehicle = TextEditingController();
  final cost = TextEditingController(text: '40');
  final note = TextEditingController();
  RideKind kind = RideKind.offer;
  String origin = 'north_gate', destination = 'riverside_metro';
  DateTime departure = defaultDeparture();
  int step = 0, seats = 3;
  bool agree = false, busy = false;
  Ride? published;
  @override
  void dispose() {
    vehicle.dispose();
    cost.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> place(bool from) async {
    final id = await choosePlace(
      context,
      title: from ? 'Pickup point' : 'Destination',
      selected: from ? origin : destination,
    );
    if (id != null && mounted) {
      setState(() {
        if (from) {
          origin = id;
        } else {
          destination = id;
        }
      });
    }
  }

  void next() {
    FocusScope.of(context).unfocus();
    if (step == 0) {
      if (origin == destination) {
        notify(context, 'Choose a different destination.');
        return;
      }
      if (!departure.isAfter(DateTime.now())) {
        notify(context, 'Choose a future departure time.');
        return;
      }
    }
    if (step == 1) {
      if (!form.currentState!.validate()) return;
      if (!agree) {
        notify(context, 'Please confirm the seat-belt and safety check.');
        return;
      }
    }
    setState(() => step++);
  }

  Future<void> publish() async {
    final student = ref.read(currentStudentProvider);
    if (student == null || busy) return;
    setState(() => busy = true);
    final ride = Ride(
      id: const Uuid().v4(),
      ownerId: student.id,
      ownerName: student.name,
      ownerAvatar: student.avatar,
      originId: origin,
      destinationId: destination,
      kind: kind,
      departureAt: departure,
      createdAt: DateTime.now(),
      totalSeats: seats,
      availableSeats: seats,
      contribution: int.tryParse(cost.text) ?? 0,
      vehicle: kind == RideKind.offer ? vehicle.text.trim() : '',
      note: note.text.trim(),
    );
    try {
      await ref.read(repositoryProvider).postRide(ride, student);
      if (mounted) setState(() => published = ride);
    } catch (error) {
      if (mounted) notify(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void startAgain() => setState(() {
    step = 0;
    published = null;
    agree = false;
    note.clear();
    vehicle.clear();
  });
  @override
  Widget build(BuildContext context) {
    ref.listen<Ride?>(postPrefillProvider, (previous, ride) {
      if (ride == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          origin = ride.originId;
          destination = ride.destinationId;
          departure = ride.departureAt;
          kind = ride.kind == RideKind.request
              ? RideKind.offer
              : RideKind.request;
          seats = kind == RideKind.offer
              ? (ride.totalSeats > 3 ? ride.totalSeats : 3)
              : ride.totalSeats;
          step = 0;
          published = null;
          agree = false;
        });
        ref.read(postPrefillProvider.notifier).state = null;
      });
    });
    if (published != null) return _Posted(ride: published!, again: startAgain);
    final offer = kind == RideKind.offer;
    return Column(
      children: [
        PageHeader(
          'Post a ride',
          back: () {
            if (step > 0) {
              setState(() => step--);
            } else {
              ref.read(tabProvider.notifier).state = AppTab.find;
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          child: Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: index <= step ? Colors.black : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: index < step
                            ? const AppIcon(
                                'check',
                                size: 13,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: index <= step
                                      ? Colors.white
                                      : AppColors.muted,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        ['Route', 'Details', 'Review'][index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: index == step
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: index <= step ? Colors.black : AppColors.muted,
                        ),
                      ),
                    ),
                    if (index < 2)
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 9),
                          child: Divider(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('post_step_$step'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      'Where are\nyou headed?',
                      'The little\ndetails.',
                      'One last\nlook.',
                    ][step],
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    [
                      'Offer a seat or ask for a lift.',
                      'A clear pickup makes a better ride.',
                      'Everything look right? You’re ready to post.',
                    ][step],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (step == 0) ..._route(offer),
                  if (step == 1) ..._details(offer),
                  if (step == 2) ..._review(offer),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    step < 2
                        ? 'Continue'
                        : offer
                        ? 'Publish ride offer'
                        : 'Publish ride request',
                    onPressed: step < 2 ? next : publish,
                    busy: busy,
                  ),
                  const SizedBox(height: 11),
                  Center(
                    child: Text(
                      'Step ${step + 1} of 3 · Your draft stays while you browse.',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _route(bool offer) => [
    Row(
      children: [
        Expanded(
          child: _RoleChoice(
            'I’m driving',
            'Offer your seats',
            'car-front',
            offer,
            () => setState(() {
              kind = RideKind.offer;
              seats = 3;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleChoice(
            'I need a ride',
            'Find your people',
            'user-round',
            !offer,
            () => setState(() {
              kind = RideKind.request;
              seats = 1;
            }),
          ),
        ),
      ],
    ),
    const SizedBox(height: 21),
    SelectTile(
      key: const ValueKey('post_origin'),
      label: 'Pick up',
      value: CampusPlace.byId(origin).name,
      subtitle: CampusPlace.byId(origin).subtitle,
      icon: 'navigation',
      onTap: () => place(true),
    ),
    const SizedBox(height: 13),
    SelectTile(
      key: const ValueKey('post_destination'),
      label: 'Destination',
      value: CampusPlace.byId(destination).name,
      subtitle: CampusPlace.byId(destination).subtitle,
      icon: 'map-pin',
      onTap: () => place(false),
    ),
    const SizedBox(height: 13),
    Row(
      children: [
        Expanded(
          child: SelectTile(
            label: 'Date',
            value: dateLabel(departure),
            icon: 'calendar-days',
            onTap: () async {
              final date = await pickCampusDate(context, departure);
              if (date != null && mounted) {
                setState(
                  () => departure = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    departure.hour,
                    departure.minute,
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: SelectTile(
            label: 'Time',
            value: timeLabel(departure),
            icon: 'clock-3',
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(departure),
              );
              if (time != null && mounted) {
                setState(
                  () => departure = DateTime(
                    departure.year,
                    departure.month,
                    departure.day,
                    time.hour,
                    time.minute,
                  ),
                );
              }
            },
          ),
        ),
      ],
    ),
    const SizedBox(height: 20),
    const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon('info', size: 16, color: AppColors.muted),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'We match the same route and day. Requests can connect within a 60-minute departure window.',
            style: TextStyle(fontSize: 10, color: AppColors.muted, height: 1.7),
          ),
        ),
      ],
    ),
  ];
  List<Widget> _details(bool offer) => [
    Surface(
      child: Row(
        children: [
          const AppIcon('armchair', size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer ? 'Seats available' : 'Seats needed',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Between 1 and 6',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fewer seats',
            onPressed: seats > 1 ? () => setState(() => seats--) : null,
            icon: AppIcon(
              'minus',
              size: 19,
              color: seats > 1 ? Colors.black : AppColors.muted,
            ),
          ),
          Text(
            '$seats',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          IconButton(
            tooltip: 'More seats',
            onPressed: seats < 6 ? () => setState(() => seats++) : null,
            icon: AppIcon(
              'plus',
              size: 19,
              color: seats < 6 ? Colors.black : AppColors.muted,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 17),
    Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: cost,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: offer
                  ? 'Fuel contribution per seat'
                  : 'Suggested contribution per seat',
              prefixText: '₹ ',
            ),
            validator: (value) {
              final amount = int.tryParse(value ?? '');
              return amount == null || amount < 0 || amount > 500
                  ? 'Enter an amount from ₹0 to ₹500.'
                  : null;
            },
          ),
          const SizedBox(height: 9),
          const Text(
            '₹0 means free. No payment is collected in the app.',
            style: TextStyle(fontSize: 9, color: AppColors.muted),
          ),
          if (offer) ...[
            const SizedBox(height: 17),
            TextFormField(
              key: const ValueKey('post_vehicle'),
              controller: vehicle,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Vehicle',
                hintText: 'Model and colour, e.g. Honda City · White',
                counterText: '',
              ),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Add your vehicle model and colour.'
                  : null,
            ),
          ],
          const SizedBox(height: 17),
          TextFormField(
            controller: note,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Pickup note (optional)',
              hintText: 'Meet by the security booth.',
              counterText: '',
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 15),
    Surface(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(7, 7, 16, 7),
      child: Row(
        children: [
          Checkbox(
            value: agree,
            onChanged: (value) => setState(() => agree = value ?? false),
          ),
          const Expanded(
            child: Text(
              'I’ll use seat belts, respect others, and only offer safe seats.',
              style: TextStyle(fontSize: 10, height: 1.7),
            ),
          ),
        ],
      ),
    ),
  ];
  List<Widget> _review(bool offer) => [
    Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoleBadge(
            driver: offer,
            label: offer ? 'Ride offer' : 'Ride request',
          ),
          const SizedBox(height: 18),
          RouteSummary(
            originId: origin,
            destinationId: destination,
            subtitles: true,
          ),
          const SizedBox(height: 12),
          DetailRow(
            'Date & time',
            '${dateLabel(departure)} · ${timeLabel(departure)}',
          ),
          DetailRow(offer ? 'Available seats' : 'Requested seats', '$seats'),
          DetailRow(
            'Suggested fuel',
            cost.text == '0' ? 'Free' : '₹${cost.text} / seat',
          ),
          if (offer) DetailRow('Vehicle', vehicle.text.trim()),
          if (note.text.trim().isNotEmpty)
            DetailRow('Pickup note', note.text.trim()),
        ],
      ),
    ),
    const SizedBox(height: 20),
    const Row(
      children: [
        AppIcon('shield-check', size: 18),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Coordinate pickup in match chat. Your email is not shown in public ride cards.',
            style: TextStyle(fontSize: 10, color: AppColors.muted, height: 1.7),
          ),
        ),
      ],
    ),
  ];
}

class _RoleChoice extends StatelessWidget {
  final String title, body, icon;
  final bool active;
  final VoidCallback tap;
  const _RoleChoice(this.title, this.body, this.icon, this.active, this.tap);
  @override
  Widget build(BuildContext context) => Material(
    color: active ? Colors.black : Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(
                  icon,
                  size: 25,
                  color: active ? Colors.white : Colors.black,
                ),
                const Spacer(),
                if (active)
                  const AppIcon('circle-check', size: 17, color: Colors.white),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              body,
              style: TextStyle(
                fontSize: 9,
                color: active ? const Color(0xFFDADADA) : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Posted extends ConsumerWidget {
  final Ride ride;
  final VoidCallback again;
  const _Posted({required this.ride, required this.again});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
    children: [
      const Brand(),
      const SizedBox(height: 40),
      const Align(
        alignment: Alignment.centerLeft,
        child: CircleAvatar(
          radius: 34,
          backgroundColor: Colors.black,
          child: AppIcon('check', size: 32, color: Colors.white),
        ),
      ),
      const SizedBox(height: 25),
      Text(
        ride.kind == RideKind.offer
            ? 'Your ride\nis live.'
            : 'Your request\nis live.',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      const SizedBox(height: 13),
      const Text(
        'One step closer to a better commute.',
        style: TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      const SizedBox(height: 29),
      Surface(
        child: Column(
          children: [
            RouteSummary(
              originId: ride.originId,
              destinationId: ride.destinationId,
            ),
            const SizedBox(height: 13),
            DetailRow(
              'Departure',
              '${dateLabel(ride.departureAt)} · ${timeLabel(ride.departureAt)}',
            ),
            DetailRow('Seats', '${ride.totalSeats}'),
          ],
        ),
      ),
      const SizedBox(height: 29),
      PrimaryButton(
        ride.kind == RideKind.offer
            ? 'Find compatible requests'
            : 'Find compatible rides',
        onPressed: () {
          ref.read(requestContextProvider.notifier).state =
              ride.kind == RideKind.request ? ride.id : null;
          ref.read(rideFiltersProvider.notifier).state = RideFilters(
            originId: ride.originId,
            destinationId: ride.destinationId,
            date: ride.departureAt,
            kind: ride.kind == RideKind.offer
                ? RideKind.request
                : RideKind.offer,
            minimumSeats: ride.kind == RideKind.request ? ride.totalSeats : 1,
            timeMinutes: ride.departureAt.hour * 60 + ride.departureAt.minute,
          );
          ref.read(tabProvider.notifier).state = AppTab.find;
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FindRideScreen()),
          );
        },
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () {
          ref.read(matchesSectionProvider.notifier).state =
              MatchesSection.posts;
          ref.read(tabProvider.notifier).state = AppTab.matches;
        },
        child: const Text('View my posts'),
      ),
      const SizedBox(height: 12),
      TextButton(onPressed: again, child: const Text('Post another ride')),
    ],
  );
}
