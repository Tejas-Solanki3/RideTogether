import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../domain/matching.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'common.dart';
import 'route_map.dart';

class RideDetailsPanel extends ConsumerStatefulWidget {
  final Ride ride;
  final BuildContext hostContext;
  const RideDetailsPanel({
    super.key,
    required this.ride,
    required this.hostContext,
  });
  @override
  ConsumerState<RideDetailsPanel> createState() => _RideDetailsPanelState();
}

class _RideDetailsPanelState extends ConsumerState<RideDetailsPanel> {
  bool saving = false;
  String? offerId;
  String riderRequestId = '';
  @override
  void initState() {
    super.initState();
    riderRequestId = ref.read(requestContextProvider) ?? '';
  }

  Future<void> _connect(Ride ride) async {
    final student = ref.read(currentStudentProvider);
    if (student == null) return;
    setState(() => saving = true);
    try {
      final repo = ref.read(repositoryProvider);
      final match = ride.kind == RideKind.offer
          ? await repo.joinOffer(ride.id, student, requestId: riderRequestId)
          : await repo.fulfilRequest(ride.id, offerId!, student);
      if (!mounted) return;
      ref.read(requestContextProvider.notifier).state = null;
      Navigator.pop(context);
      if (widget.hostContext.mounted) {
        openPanel(
          widget.hostContext,
          ConfirmationPanel(match: match, hostContext: widget.hostContext),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        notify(context, friendlyError(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProvider);
    final all = ref.watch(ridesProvider).valueOrNull ?? [];
    final ride =
        all.where((r) => r.id == widget.ride.id).firstOrNull ?? widget.ride;
    final offers = all
        .where((r) => compatibleOfferForRequest(r, ride, student?.id ?? ''))
        .toList();
    final driver = ride.kind == RideKind.offer;
    final ownRequests = driver
        ? all
              .where(
                (r) =>
                    r.ownerId == student?.id &&
                    compatibleOfferForRequest(ride, r, ride.ownerId),
              )
              .toList()
        : <Ride>[];
    if (!ownRequests.any((r) => r.id == riderRequestId)) riderRequestId = '';
    final reserved =
        ownRequests
            .where((r) => r.id == riderRequestId)
            .firstOrNull
            ?.totalSeats ??
        1;
    final existing = (ref.watch(matchesProvider).valueOrNull ?? [])
        .where(
          (m) =>
              m.offerId == ride.id &&
              m.riderId == student?.id &&
              m.status == MatchStatus.confirmed,
        )
        .firstOrNull;
    final unavailable =
        !ride.active ||
        ride.availableSeats == 0 ||
        !ride.departureAt.isAfter(DateTime.now());
    if (!driver && offers.isNotEmpty && !offers.any((r) => r.id == offerId)) {
      offerId = offers.first.id;
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelHeader(driver ? 'A ride your way' : 'Someone needs a lift'),
            const SizedBox(height: 13),
            Row(
              children: [
                RoleBadge(
                  driver: driver,
                  label: driver ? 'Ride offer' : 'Ride request',
                ),
                const Spacer(),
                const LiveDot(),
              ],
            ),
            const SizedBox(height: 19),
            RouteMap(
              originId: ride.originId,
              destinationId: ride.destinationId,
              height: 176,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Avatar(name: ride.ownerName, asset: ride.ownerAvatar, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.ownerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ref.watch(repositoryProvider).isDemo
                            ? 'Sample campus member · demo'
                            : 'Verified campus email',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  ride.contribution == 0 ? 'Free' : '₹${ride.contribution}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 23),
            const Divider(),
            const SizedBox(height: 21),
            RouteRow(
              origin: ride.origin,
              destination: ride.destination,
              vertical: true,
            ),
            const SizedBox(height: 23),
            Row(
              children: [
                Expanded(
                  child: DetailTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: dateLabel(ride.departureAt, long: true),
                  ),
                ),
                Expanded(
                  child: DetailTile(
                    icon: Icons.schedule,
                    label: 'Departure',
                    value: timeLabel(ride.departureAt),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: DetailTile(
                    icon: Icons.airline_seat_recline_normal,
                    label: driver ? 'Available seats' : 'Seats requested',
                    value:
                        '${ride.availableSeats} ${ride.availableSeats == 1 ? 'seat' : 'seats'}',
                  ),
                ),
                Expanded(
                  child: DetailTile(
                    icon: Icons.payments_outlined,
                    label: driver ? 'Contribution / seat' : 'Suggested / seat',
                    value: ride.contribution == 0
                        ? '₹0 · free'
                        : '₹${ride.contribution}',
                  ),
                ),
              ],
            ),
            if (driver) ...[
              const SizedBox(height: 18),
              DetailTile(
                icon: Icons.drive_eta_outlined,
                label: 'Look for',
                value: ride.vehicle,
              ),
            ],
            if (ride.note.isNotEmpty) ...[
              const SizedBox(height: 21),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A note for the journey',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ride.note,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (driver && ownRequests.isNotEmpty && existing == null) ...[
              const SizedBox(height: 20),
              const Text(
                'Reserve for your journey',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                key: ValueKey(riderRequestId),
                initialValue: riderRequestId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text(
                      'Just me · 1 seat',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  ...ownRequests.map(
                    (r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        'My request · ${r.totalSeats} seats · ${timeLabel(r.departureAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => riderRequestId = v!),
              ),
              if (riderRequestId.isNotEmpty) ...[
                const SizedBox(height: 9),
                const Text(
                  'Your request will be marked matched when you connect.',
                  style: TextStyle(fontSize: 10, color: AppColors.green),
                ),
              ],
            ],
            if (!driver && offers.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Connect using your matching offer',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                initialValue: offerId,
                isExpanded: true,
                items: offers
                    .map(
                      (o) => DropdownMenuItem(
                        value: o.id,
                        child: Text(
                          '${timeLabel(o.departureAt)} · ${o.availableSeats} seats · ${o.vehicle}',
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => offerId = v),
              ),
              const SizedBox(height: 9),
              Text(
                '${ride.totalSeats} ${ride.totalSeats == 1 ? 'seat will' : 'seats will'} be reserved on your offer.',
                style: const TextStyle(fontSize: 10, color: AppColors.green),
              ),
            ],
            if (!driver && offers.isEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'You’ll need an offer on this route and date, within 60 minutes, with enough seats.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  height: 1.7,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: existing != null
                  ? PrimaryButton(
                      label: 'View your connection',
                      onPressed: () {
                        ref.read(tabProvider.notifier).state = AppTab.matches;
                        ref.read(matchesSectionProvider.notifier).state =
                            MatchesSection.upcoming;
                        Navigator.pop(context);
                      },
                    )
                  : !driver && offers.isEmpty && !unavailable
                  ? PrimaryButton(
                      label: 'Post a matching offer',
                      onPressed: () {
                        ref.read(postPrefillProvider.notifier).state = ride;
                        ref.read(tabProvider.notifier).state = AppTab.post;
                        Navigator.pop(context);
                      },
                    )
                  : PrimaryButton(
                      label: unavailable
                          ? 'No longer available'
                          : driver
                          ? 'Connect & reserve $reserved ${reserved == 1 ? 'seat' : 'seats'}'
                          : 'Offer a lift',
                      loading: saving,
                      onPressed: unavailable ? null : () => _connect(ride),
                    ),
            ),
            const SizedBox(height: 11),
            const Center(
              child: Text(
                'No payment now. Confirm your pickup in chat.',
                style: TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmationPanel extends ConsumerWidget {
  final RideMatch match;
  final BuildContext hostContext;
  const ConfirmationPanel({
    super.key,
    required this.match,
    required this.hostContext,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = match.isDriver(ref.watch(currentStudentProvider)?.id ?? '');
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PanelHeader('Your next ride, sorted.'),
            const SizedBox(height: 16),
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.green,
                size: 38,
              ),
            ),
            const SizedBox(height: 22),
            const Eyebrow('You’re connected'),
            const SizedBox(height: 10),
            Text(
              'Good company,\nconfirmed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 13),
            Text(
              '${match.seats} ${match.seats == 1 ? 'seat is' : 'seats are'} reserved. The offer’s availability\nhas updated across the app.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 25),
            Surface(
              color: AppColors.background,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RouteRow(
                    origin: match.origin,
                    destination: match.destination,
                    vertical: true,
                  ),
                  const SizedBox(height: 19),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      InfoItem(
                        Icons.calendar_today_outlined,
                        dateLabel(match.departureAt),
                      ),
                      InfoItem(Icons.schedule, timeLabel(match.departureAt)),
                      InfoItem(
                        Icons.airline_seat_recline_normal,
                        '${match.seats} reserved',
                      ),
                    ],
                  ),
                  const SizedBox(height: 19),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Avatar(
                        name: driver ? match.riderName : match.driverName,
                        asset: driver ? match.riderAvatar : match.driverAvatar,
                        size: 35,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver ? match.riderName : match.driverName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              driver ? 'Your rider' : 'Your driver',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RoleBadge(driver: !driver),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 23),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Say hello in chat',
                icon: Icons.chat_bubble_outline,
                onPressed: () {
                  Navigator.pop(context);
                  openPanel(hostContext, ChatPanel(match: match), width: 560);
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.read(tabProvider.notifier).state = AppTab.matches;
                ref.read(matchesSectionProvider.notifier).state =
                    MatchesSection.upcoming;
                Navigator.pop(context);
              },
              child: const Text('View my matches'),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchDetailsPanel extends ConsumerWidget {
  final RideMatch match;
  final BuildContext hostContext;
  const MatchDetailsPanel({
    super.key,
    required this.match,
    required this.hostContext,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m =
        (ref.watch(matchesProvider).valueOrNull ?? [])
            .where((e) => e.id == match.id)
            .firstOrNull ??
        match;
    final driver = m.isDriver(ref.watch(currentStudentProvider)?.id ?? '');
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PanelHeader('Your ride details'),
            const SizedBox(height: 12),
            Row(
              children: [
                RoleBadge(
                  driver: driver,
                  label: driver ? 'You’re driving' : 'You’re riding',
                ),
                const Spacer(),
                Text(
                  m.status == MatchStatus.cancelled ? 'Cancelled' : 'Connected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: m.status == MatchStatus.cancelled
                        ? AppColors.red
                        : AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            RouteMap(
              originId: m.originId,
              destinationId: m.destinationId,
              height: 180,
            ),
            const SizedBox(height: 23),
            RouteRow(
              origin: m.origin,
              destination: m.destination,
              vertical: true,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DetailTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: dateLabel(m.departureAt, long: true),
                  ),
                ),
                Expanded(
                  child: DetailTile(
                    icon: Icons.schedule,
                    label: 'Time',
                    value: timeLabel(m.departureAt),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 19),
            Row(
              children: [
                Expanded(
                  child: DetailTile(
                    icon: Icons.airline_seat_recline_normal,
                    label: 'Reserved',
                    value: '${m.seats} seats',
                  ),
                ),
                Expanded(
                  child: DetailTile(
                    icon: Icons.payments_outlined,
                    label: 'Contribution',
                    value: '₹${m.contribution * m.seats} total',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 19),
            DetailTile(
              icon: Icons.drive_eta_outlined,
              label: 'Vehicle',
              value: m.vehicle,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Avatar(
                  name: driver ? m.riderName : m.driverName,
                  asset: driver ? m.riderAvatar : m.driverAvatar,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    driver ? m.riderName : m.driverName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                RoleBadge(driver: !driver),
              ],
            ),
            const SizedBox(height: 23),
            const Text(
              'Settle any fuel contribution directly with your driver. RideTogether does not process payments.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 23),
            if (m.status == MatchStatus.confirmed)
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Open conversation',
                  onPressed: () {
                    Navigator.pop(context);
                    openPanel(hostContext, ChatPanel(match: m), width: 560);
                  },
                ),
              ),
            if (m.status == MatchStatus.confirmed &&
                m.departureAt.isAfter(DateTime.now()))
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  onPressed: () => _cancel(context, ref, m),
                  child: const Text('Cancel this connection'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, RideMatch m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this connection?'),
        content: Text(
          '${m.seats} ${m.seats == 1 ? 'seat will' : 'seats will'} be returned to the driver’s offer. Let your travel partner know first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep ride'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Cancel connection'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(repositoryProvider)
          .cancelMatch(m.id, ref.read(currentStudentProvider)!);
      if (context.mounted) {
        Navigator.pop(context);
        if (hostContext.mounted) {
          notify(
            hostContext,
            'Connection cancelled. Seats returned to the offer.',
          );
        }
      }
    } catch (e) {
      if (context.mounted) notify(context, friendlyError(e), error: true);
    }
  }
}

class ChatPanel extends ConsumerStatefulWidget {
  final RideMatch match;
  const ChatPanel({super.key, required this.match});
  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final text = TextEditingController();
  final scroll = ScrollController();
  bool sending = false;
  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? quick]) async {
    final value = quick ?? text.text;
    if (value.trim().isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await ref
          .read(repositoryProvider)
          .sendMessage(
            widget.match.id,
            ref.read(currentStudentProvider)!,
            value,
          );
      if (!mounted) return;
      text.clear();
      setState(() => sending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => sending = false);
        notify(context, friendlyError(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentStudentProvider)?.id ?? '';
    final match =
        (ref.watch(matchesProvider).valueOrNull ?? [])
            .where((m) => m.id == widget.match.id)
            .firstOrNull ??
        widget.match;
    final driver = match.isDriver(uid),
        demo = ref.watch(repositoryProvider).isDemo;
    final messages = ref.watch(messagesProvider(match.id));
    final cancelled = match.status == MatchStatus.cancelled;
    final height = (MediaQuery.sizeOf(context).height * .76).clamp(
      360.0,
      660.0,
    );
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            PanelHeader(
              driver ? match.riderName : match.driverName,
              leading: Avatar(
                name: driver ? match.riderName : match.driverName,
                asset: driver ? match.riderAvatar : match.driverAvatar,
                size: 38,
              ),
            ),
            Row(
              children: [
                RoleBadge(driver: !driver),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '${dateLabel(match.departureAt)} · ${timeLabel(match.departureAt)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                demo
                    ? 'Local demo chat · saved on this device. No other person is online.'
                    : 'Keep pickup details here. Only you and your travel partner can read this chat.',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.green,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: messages.when(
                data: (items) => items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.waving_hand_outlined,
                              size: 34,
                              color: AppColors.green,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'A hello goes a long way.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Confirm where and when you’ll meet.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        itemCount: items.length,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemBuilder: (_, i) {
                          final msg = items[i], mine = msg.senderId == uid;
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 340),
                              margin: const EdgeInsets.only(bottom: 11),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? AppColors.ink
                                    : AppColors.background,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(mine ? 16 : 4),
                                  bottomRight: Radius.circular(mine ? 4 : 16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.7,
                                      color: mine
                                          ? Colors.white
                                          : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    timeLabel(msg.createdAt),
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: mine
                                          ? Colors.white.withValues(alpha: .6)
                                          : AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) => Center(
                  child: Text(friendlyError(e), textAlign: TextAlign.center),
                ),
              ),
            ),
            if (!cancelled) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                      ),
                      onPressed: sending
                          ? null
                          : () => _send('I’m at the pickup point.'),
                      child: const Text(
                        'I’m at the pickup point',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                      ),
                      onPressed: sending
                          ? null
                          : () => _send(
                              'Running 5 minutes late. Thanks for waiting!',
                            ),
                      child: const Text(
                        'Running 5 min late',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: text,
                      enabled: !sending,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 1000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Say hello. Confirm your pickup.',
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: sending ? null : () => _send(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(15),
                    ),
                    icon: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'This connection was cancelled. Chat is now read-only.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
