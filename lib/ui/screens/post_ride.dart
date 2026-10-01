import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models.dart';
import '../../domain/matching.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/route_map.dart';

class PostRideScreen extends ConsumerStatefulWidget {
  const PostRideScreen({super.key});
  @override
  ConsumerState<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends ConsumerState<PostRideScreen> {
  int step = 0, seats = 3;
  RideKind kind = RideKind.offer;
  String origin = 'north_gate', destination = 'riverside_metro';
  DateTime date = defaultDeparture();
  TimeOfDay time = TimeOfDay.fromDateTime(defaultDeparture());
  final vehicle = TextEditingController();
  final note = TextEditingController();
  final price = TextEditingController(text: '40');
  final routeForm = GlobalKey<FormState>();
  final detailsForm = GlobalKey<FormState>();
  final scroll = ScrollController();
  bool agreement = false, saving = false;
  String? agreementError;
  @override
  void initState() {
    super.initState();
    final prefill = ref.read(postPrefillProvider);
    if (prefill != null) _prefill(prefill);
  }

  void _prefill(Ride ride) {
    origin = ride.originId;
    destination = ride.destinationId;
    kind = ride.kind == RideKind.request ? RideKind.offer : RideKind.request;
    date = ride.departureAt;
    if (!date.isAfter(DateTime.now())) date = defaultDeparture();
    time = TimeOfDay.fromDateTime(date);
    seats = ride.totalSeats;
    price.text = '${ride.contribution}';
    step = 0;
    agreement = false;
  }

  @override
  void dispose() {
    vehicle.dispose();
    note.dispose();
    price.dispose();
    scroll.dispose();
    super.dispose();
  }

  DateTime get departure =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);
  void _go(int next) {
    setState(() => step = next);
    if (scroll.hasClients) {
      scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _next() {
    if (step == 0) {
      if (!routeForm.currentState!.validate()) return;
      if (!departure.isAfter(DateTime.now())) {
        notify(context, 'Choose a departure time in the future.', error: true);
        return;
      }
      _go(1);
    } else {
      if (!detailsForm.currentState!.validate()) return;
      if (!agreement) {
        setState(
          () => agreementError = 'Please confirm the travel guidelines.',
        );
        return;
      }
      _go(2);
    }
  }

  Future<void> _publish() async {
    final student = ref.read(currentStudentProvider);
    if (student == null) return;
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
      contribution: int.tryParse(price.text) ?? 0,
      vehicle: kind == RideKind.offer ? vehicle.text.trim() : '',
      note: note.text.trim(),
    );
    try {
      validateRide(ride, student);
      setState(() => saving = true);
      await ref.read(repositoryProvider).postRide(ride, student);
      if (!mounted) return;
      setState(() {
        saving = false;
        step = 0;
        agreement = false;
        note.clear();
        vehicle.clear();
      });
      await openPanel(context, _PostedPanel(ride: ride));
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        notify(context, friendlyError(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Ride?>(postPrefillProvider, (previous, next) {
      if (next != null) {
        setState(() => _prefill(next));
        ref.read(postPrefillProvider.notifier).state = null;
      }
    });
    return LayoutBuilder(
      builder: (context, c) {
        final mobile = c.maxWidth < 650, aside = c.maxWidth > 950;
        return SingleChildScrollView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(
            mobile ? 20 : 36,
            30,
            mobile ? 20 : 36,
            40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('A little less solo. A lot more together.'),
                  const SizedBox(height: 11),
                  Text(
                    'A shared ride starts here.',
                    style: mobile
                        ? Theme.of(context).textTheme.headlineMedium
                        : Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Offer a seat or ask for a lift. We’ll help you find your people.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _Progress(step: step),
                            const SizedBox(height: 21),
                            Surface(
                              padding: EdgeInsets.all(mobile ? 21 : 30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Eyebrow(
                                    '0${step + 1} / ${['Your journey', 'The little details', 'One last look'][step]}',
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    [
                                      'Where are you headed?',
                                      'Make the ride yours.',
                                      'Ready to go together?',
                                    ][step],
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    [
                                      'Start with your role and route.',
                                      'Clear details make for easy meetups.',
                                      'Review your ride before the campus sees it.',
                                    ][step],
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: switch (step) {
                                      0 => _routeStep(mobile),
                                      1 => _detailsStep(),
                                      _ => _reviewStep(),
                                    },
                                  ),
                                  const SizedBox(height: 26),
                                  const Divider(),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: [
                                      if (step > 0) ...[
                                        OutlinedButton.icon(
                                          onPressed: saving
                                              ? null
                                              : () => _go(step - 1),
                                          icon: const Icon(
                                            Icons.arrow_back_rounded,
                                            size: 16,
                                          ),
                                          label: const Text('Back'),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Expanded(
                                        child: PrimaryButton(
                                          label: step == 2
                                              ? (kind == RideKind.offer
                                                    ? 'Publish ride offer'
                                                    : 'Publish ride request')
                                              : 'Continue',
                                          onPressed: step == 2
                                              ? _publish
                                              : _next,
                                          loading: saving,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      step == 2
                                          ? 'No payment is taken. Coordinate directly in chat.'
                                          : 'Step ${step + 1} of 3 · Your draft stays here while you browse.',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: AppColors.muted,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (aside) ...[
                        const SizedBox(width: 25),
                        SizedBox(
                          width: 290,
                          child: Column(
                            children: [
                              Surface(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'The journey ahead',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    RouteMap(
                                      originId: origin,
                                      destinationId: destination,
                                      height: 226,
                                    ),
                                    const SizedBox(height: 14),
                                    RouteRow(
                                      origin: CampusPlace.byId(origin),
                                      destination: CampusPlace.byId(
                                        destination,
                                      ),
                                      vertical: true,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Illustrative map · confirm pickup in chat',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 17),
                              Surface(
                                color: AppColors.sage,
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.handshake_outlined,
                                      color: AppColors.green,
                                      size: 27,
                                    ),
                                    const SizedBox(height: 13),
                                    const Text(
                                      'Good rides start\nwith good details.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 21,
                                        height: 1.3,
                                        letterSpacing: -.6,
                                      ),
                                    ),
                                    const SizedBox(height: 13),
                                    _tip('Be specific about your pickup.'),
                                    _tip('Only offer seats with seat belts.'),
                                    _tip('Keep plans and contact in chat.'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_rounded, size: 15, color: AppColors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.green, fontSize: 11),
          ),
        ),
      ],
    ),
  );
  Widget _routeStep(bool mobile) => Form(
    key: routeForm,
    child: Column(
      key: const ValueKey('route'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _RoleChoice(
                driver: true,
                selected: kind == RideKind.offer,
                onTap: () => setState(() {
                  kind = RideKind.offer;
                  seats = 3;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleChoice(
                driver: false,
                selected: kind == RideKind.request,
                onTap: () => setState(() {
                  kind = RideKind.request;
                  seats = 1;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: origin,
          key: ValueKey('origin_$origin'),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Pickup point',
            prefixIcon: Icon(Icons.trip_origin, size: 18),
          ),
          items: CampusPlace.all
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => origin = v!),
          validator: (v) =>
              v == destination ? 'Choose a different pickup point.' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: destination,
          key: ValueKey('destination_$destination'),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Destination',
            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
          ),
          items: CampusPlace.all
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => destination = v!),
          validator: (v) =>
              v == origin ? 'Pickup and destination must be different.' : null,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _PickerField(
                label: 'Departure date',
                value: dateLabel(date, long: true),
                icon: Icons.calendar_today_outlined,
                onTap: () async {
                  final now = DateTime.now();
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: date.isBefore(now) ? now : date,
                    firstDate: DateTime(now.year, now.month, now.day),
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (selected != null) setState(() => date = selected);
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _PickerField(
                label: 'Departure time',
                value: time.format(context),
                icon: Icons.schedule_rounded,
                onTap: () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (selected != null) setState(() => time = selected);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 15, color: AppColors.muted),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'We match the same route and date. Requests can connect to offers within a 60-minute departure window.',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _detailsStep() => Form(
    key: detailsForm,
    child: Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind == RideKind.offer ? 'Available seats' : 'Seats needed',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Between 1 and 6 seats',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Fewer seats',
              onPressed: seats > 1 ? () => setState(() => seats--) : null,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.background,
              ),
              icon: const Icon(Icons.remove, size: 19),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$seats',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'More seats',
              onPressed: seats < 6 ? () => setState(() => seats++) : null,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.background,
              ),
              icon: const Icon(Icons.add, size: 19),
            ),
          ],
        ),
        const SizedBox(height: 25),
        TextFormField(
          controller: price,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: kind == RideKind.offer
                ? 'Fuel contribution per seat'
                : 'Suggested contribution per seat',
            prefixText: '₹ ',
            helperText: 'Optional · enter 0 for a free ride · maximum ₹500',
          ),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n < 0 || n > 500
                ? 'Enter an amount from ₹0 to ₹500.'
                : null;
          },
        ),
        if (kind == RideKind.offer) ...[
          const SizedBox(height: 20),
          TextFormField(
            controller: vehicle,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Vehicle',
              hintText: 'e.g. Hyundai i20 · White',
              prefixIcon: Icon(Icons.drive_eta_outlined, size: 20),
            ),
            validator: (v) => (v ?? '').trim().length < 2
                ? 'Add your vehicle model and colour.'
                : null,
          ),
        ],
        const SizedBox(height: 18),
        TextFormField(
          controller: note,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            labelText: 'Pickup note (optional)',
            hintText: 'Exact meeting spot, luggage space, or anything helpful.',
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.sage,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                height: 27,
                child: Checkbox(
                  value: agreement,
                  activeColor: AppColors.green,
                  onChanged: (v) => setState(() {
                    agreement = v!;
                    agreementError = null;
                  }),
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'I’ll use seat belts, travel responsibly, and confirm pickup details in chat.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.green,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (agreementError != null) ...[
          const SizedBox(height: 7),
          Text(
            agreementError!,
            style: const TextStyle(fontSize: 11, color: AppColors.red),
          ),
        ],
      ],
    ),
  );
  Widget _reviewStep() => Column(
    key: const ValueKey('review'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          RoleBadge(
            driver: kind == RideKind.offer,
            label: kind == RideKind.offer ? 'Ride offer' : 'Ride request',
          ),
          const Spacer(),
          TextButton(onPressed: () => _go(0), child: const Text('Edit route')),
        ],
      ),
      const SizedBox(height: 12),
      RouteRow(
        origin: CampusPlace.byId(origin),
        destination: CampusPlace.byId(destination),
        vertical: true,
      ),
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 23),
      Row(
        children: [
          Expanded(
            child: DetailTile(
              icon: Icons.calendar_today_outlined,
              label: 'Departure date',
              value: dateLabel(departure, long: true),
            ),
          ),
          Expanded(
            child: DetailTile(
              icon: Icons.schedule_rounded,
              label: 'Departure time',
              value: timeLabel(departure),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: DetailTile(
              icon: Icons.airline_seat_recline_normal_rounded,
              label: kind == RideKind.offer
                  ? 'Seats available'
                  : 'Seats needed',
              value: '$seats ${seats == 1 ? 'seat' : 'seats'}',
            ),
          ),
          Expanded(
            child: DetailTile(
              icon: Icons.payments_outlined,
              label: 'Per seat',
              value: price.text == '0' ? 'Free' : '₹${price.text}',
            ),
          ),
        ],
      ),
      if (kind == RideKind.offer) ...[
        const SizedBox(height: 20),
        DetailTile(
          icon: Icons.drive_eta_outlined,
          label: 'Vehicle',
          value: vehicle.text,
        ),
      ],
      if (note.text.isNotEmpty) ...[
        const SizedBox(height: 22),
        const Text(
          'Pickup note',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 5),
        Text(note.text, style: const TextStyle(fontSize: 12, height: 1.7)),
      ],
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => _go(1),
          child: const Text('Edit details'),
        ),
      ),
    ],
  );
}

class _RoleChoice extends StatelessWidget {
  final bool driver, selected;
  final VoidCallback onTap;
  const _RoleChoice({
    required this.driver,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? (driver ? AppColors.sage : AppColors.blueLight)
        : AppColors.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: BorderSide(
        color: selected
            ? (driver ? AppColors.green : AppColors.blue)
            : AppColors.line,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  driver
                      ? Icons.drive_eta_outlined
                      : Icons.person_outline_rounded,
                  size: 26,
                  color: driver ? AppColors.green : AppColors.blue,
                ),
                const Spacer(),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: driver ? AppColors.green : AppColors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              driver ? 'I’m driving' : 'I need a ride',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              driver ? 'Offer your spare seats' : 'Find your campus lift',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PickerField extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Progress extends StatelessWidget {
  final int step;
  const _Progress({required this.step});
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      3,
      (i) => Expanded(
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: i <= step ? AppColors.ink : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: i <= step ? AppColors.ink : AppColors.line,
                ),
              ),
              child: Center(
                child: i < step
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : Text(
                        '0${i + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: i <= step ? Colors.white : AppColors.muted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ['Route', 'Details', 'Review'][i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: i <= step ? AppColors.ink : AppColors.muted,
              ),
            ),
            if (i < 2)
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.line,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _PostedPanel extends ConsumerWidget {
  final Ride ride;
  const _PostedPanel({required this.ride});
  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PanelHeader('You’re on the map'),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(23),
            decoration: const BoxDecoration(
              color: AppColors.sage,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 35,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 23),
          Text(
            ride.kind == RideKind.offer
                ? 'Your ride is live.'
                : 'Your request is live.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 9),
          const Text(
            'One step closer to a better commute.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 23),
          Surface(
            color: AppColors.background,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                RouteRow(
                  origin: ride.origin,
                  destination: ride.destination,
                  vertical: true,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    InfoItem(
                      Icons.calendar_today_outlined,
                      dateLabel(ride.departureAt),
                    ),
                    InfoItem(Icons.schedule, timeLabel(ride.departureAt)),
                    InfoItem(
                      Icons.airline_seat_recline_normal,
                      '${ride.totalSeats} seats',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: ride.kind == RideKind.offer
                  ? 'Find compatible requests'
                  : 'Find compatible rides',
              onPressed: () {
                ref.read(rideFiltersProvider.notifier).state = RideFilters(
                  originId: ride.originId,
                  destinationId: ride.destinationId,
                  date: ride.departureAt,
                  kind: ride.kind == RideKind.offer
                      ? RideKind.request
                      : RideKind.offer,
                  minimumSeats: ride.kind == RideKind.request
                      ? ride.totalSeats
                      : 1,
                  timeMinutes:
                      ride.departureAt.hour * 60 + ride.departureAt.minute,
                );
                ref.read(requestContextProvider.notifier).state =
                    ride.kind == RideKind.request ? ride.id : null;
                ref.read(tabProvider.notifier).state = AppTab.find;
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 7),
          TextButton(
            onPressed: () {
              ref.read(matchesSectionProvider.notifier).state =
                  MatchesSection.posts;
              ref.read(tabProvider.notifier).state = AppTab.matches;
              Navigator.pop(context);
            },
            child: const Text('View my posts'),
          ),
        ],
      ),
    ),
  );
}
