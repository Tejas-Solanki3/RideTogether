import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../domain/matching.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/route_map.dart';
import 'chat.dart';

void showMyRides(BuildContext context, WidgetRef ref) {
  ref.read(matchesSectionProvider.notifier).state = MatchesSection.upcoming;
  ref.read(tabProvider.notifier).state = AppTab.matches;
  Navigator.of(context).popUntil((r) => r.isFirst);
}

class RideDetailsScreen extends ConsumerStatefulWidget {
  final String rideId;
  const RideDetailsScreen({super.key, required this.rideId});
  @override
  ConsumerState<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends ConsumerState<RideDetailsScreen> {
  String? requestChoice, offerChoice;
  bool busy = false;
  Future<void> reserve(Ride ride, String requestId, String offerId) async {
    final student = ref.read(currentStudentProvider);
    if (student == null || busy) return;
    setState(() => busy = true);
    try {
      final repo = ref.read(repositoryProvider);
      final m = ride.kind == RideKind.offer
          ? await repo.joinOffer(ride.id, student, requestId: requestId)
          : await repo.fulfilRequest(ride.id, offerId, student);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => ConfirmationScreen(match: m)),
        );
      }
    } catch (e) {
      if (mounted) notify(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ridesProvider),
        student = ref.watch(currentStudentProvider);
    final rides = data.valueOrNull ?? [];
    final found = rides.where((r) => r.id == widget.rideId).toList();
    if (found.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PageHeader('Ride details', back: () => Navigator.pop(context)),
              Expanded(
                child: data.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const EmptyState(
                        'Ride unavailable',
                        'This post is no longer available.',
                      ),
              ),
            ],
          ),
        ),
      );
    }
    final ride = found.first,
        offer = ride.kind == RideKind.offer,
        own = ride.ownerId == student?.id;
    final matches = ref.watch(matchesProvider).valueOrNull ?? [];
    final existing = matches
        .where((m) => m.offerId == ride.id && m.riderId == student?.id)
        .toList();
    final requests = offer
        ? rides
              .where(
                (r) =>
                    r.ownerId == student?.id &&
                    r.kind == RideKind.request &&
                    compatibleOfferForRequest(ride, r, ride.ownerId),
              )
              .toList()
        : <Ride>[];
    final preference = requestChoice ?? ref.watch(requestContextProvider) ?? '';
    final selectedReq = requests.where((r) => r.id == preference).toList();
    final request = selectedReq.isEmpty ? null : selectedReq.first;
    final count = request?.totalSeats ?? 1;
    final compatible = offer
        ? <Ride>[]
        : rides
              .where(
                (r) => compatibleOfferForRequest(r, ride, student?.id ?? ''),
              )
              .toList();
    final selection = compatible.where((r) => r.id == offerChoice).toList();
    final selectedOffer = selection.isNotEmpty
        ? selection.first
        : (compatible.isEmpty ? null : compatible.first);
    final eligible =
        ride.active &&
        ride.departureAt.isAfter(DateTime.now()) &&
        (offer ? ride.availableSeats >= count : selectedOffer != null);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              offer ? 'Ride details' : 'Ride request',
              back: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  RouteMap(
                    originId: ride.originId,
                    destinationId: ride.destinationId,
                    height: 170,
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'ILLUSTRATIVE CAMPUS MAP · NOT NAVIGATION',
                    style: TextStyle(
                      fontSize: 7,
                      color: AppColors.muted,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Avatar(
                        name: ride.ownerName,
                        asset: ride.ownerAvatar,
                        size: 49,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.ownerName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              offer
                                  ? ride.vehicle
                                  : 'Looking for a campus lift',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RoleBadge(driver: offer),
                    ],
                  ),
                  const SizedBox(height: 23),
                  Surface(
                    child: Column(
                      children: [
                        RouteSummary(
                          originId: ride.originId,
                          destinationId: ride.destinationId,
                          subtitles: true,
                        ),
                        const SizedBox(height: 12),
                        DetailRow(
                          'Date & time',
                          '${dateLabel(ride.departureAt)} · ${timeLabel(ride.departureAt)}',
                        ),
                        DetailRow(
                          offer ? 'Seats available' : 'Seats requested',
                          '${ride.availableSeats}',
                        ),
                        DetailRow(
                          'Suggested fuel',
                          ride.contribution == 0
                              ? 'Free'
                              : '₹${ride.contribution} / seat',
                        ),
                      ],
                    ),
                  ),
                  if (ride.note.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Surface(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppIcon('message-circle', size: 19),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pickup note',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
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
                      ),
                    ),
                  ],
                  if (!own &&
                      existing.isEmpty &&
                      offer &&
                      requests.isNotEmpty) ...[
                    const SizedBox(height: 19),
                    Surface(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(request?.id ?? 'one_seat'),
                        initialValue: request?.id ?? '',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Who are you booking for?',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text(
                              'Just me · 1 seat',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          ...requests.map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                'My request · ${r.totalSeats} seats · ${timeLabel(r.departureAt)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => requestChoice = v),
                      ),
                    ),
                  ],
                  if (!own && !offer) ...[
                    const SizedBox(height: 19),
                    if (compatible.isNotEmpty)
                      Surface(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(selectedOffer?.id),
                          initialValue: selectedOffer?.id,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Connect using your offer',
                          ),
                          items: compatible
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r.id,
                                  child: Text(
                                    '${timeLabel(r.departureAt)} · ${r.availableSeats} seats · ${r.vehicle}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => offerChoice = v),
                        ),
                      )
                    else
                      Surface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Post a compatible offer first.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Same route and day, within 60 minutes, with enough seats for the whole request.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                ref.read(postPrefillProvider.notifier).state =
                                    ride;
                                ref.read(tabProvider.notifier).state =
                                    AppTab.post;
                                Navigator.of(
                                  context,
                                ).popUntil((r) => r.isFirst);
                              },
                              child: const Text('Post a matching offer'),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 19),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIcon('shield-check', size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Coordinate pickup directly. This is a campus carpool, not a taxi or payment service.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (own)
                    PrimaryButton(
                      'View my rides',
                      onPressed: () => showMyRides(context, ref),
                    )
                  else if (existing.isNotEmpty)
                    PrimaryButton(
                      existing.first.status == MatchStatus.confirmed
                          ? 'View your connection'
                          : 'Connection cancelled',
                      onPressed: existing.first.status == MatchStatus.confirmed
                          ? () => showMyRides(context, ref)
                          : null,
                    )
                  else
                    PrimaryButton(
                      offer
                          ? 'Reserve $count ${count == 1 ? 'seat' : 'seats'}'
                          : 'Offer a lift · ${ride.totalSeats} ${ride.totalSeats == 1 ? 'seat' : 'seats'}',
                      onPressed: eligible
                          ? () => reserve(
                              ride,
                              request?.id ?? '',
                              selectedOffer?.id ?? '',
                            )
                          : null,
                      busy: busy,
                    ),
                  const SizedBox(height: 9),
                  const Text(
                    'No payment now. Availability updates after confirmation.',
                    style: TextStyle(fontSize: 8, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmationScreen extends ConsumerWidget {
  final RideMatch match;
  const ConfirmationScreen({super.key, required this.match});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentStudentProvider)?.id ?? '',
        driver = match.driverId == uid;
    final person = driver ? match.riderName : match.driverName,
        avatar = driver ? match.riderAvatar : match.driverAvatar;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Brand(),
            const SizedBox(height: 40),
            const Align(
              alignment: Alignment.centerLeft,
              child: AppIllustration('good_company', width: 260, height: 150),
            ),
            const SizedBox(height: 26),
            Text(
              'You’re\nconnected.',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 39),
            ),
            const SizedBox(height: 16),
            Text(
              '${match.seats} ${match.seats == 1 ? 'seat is' : 'seats are'} reserved.\nAvailability has updated for everyone.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 28),
            Surface(
              color: AppColors.background,
              child: Column(
                children: [
                  RouteSummary(
                    originId: match.originId,
                    destinationId: match.destinationId,
                  ),
                  const SizedBox(height: 12),
                  DetailRow(
                    'Departure',
                    '${dateLabel(match.departureAt)} · ${timeLabel(match.departureAt)}',
                  ),
                  DetailRow('Reserved seats', '${match.seats}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Avatar(name: person, asset: avatar, size: 45),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
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
            const SizedBox(height: 29),
            PrimaryButton(
              'Say hello in chat',
              icon: 'message-circle',
              onPressed: () {
                final nav = Navigator.of(context);
                ref.read(tabProvider.notifier).state = AppTab.matches;
                nav.popUntil((r) => r.isFirst);
                nav.push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatScreen(match: match),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => showMyRides(context, ref),
              child: const Text('View my rides'),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchDetailsScreen extends ConsumerStatefulWidget {
  final RideMatch match;
  const MatchDetailsScreen({super.key, required this.match});
  @override
  ConsumerState<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends ConsumerState<MatchDetailsScreen> {
  bool busy = false;
  Future<void> cancel(RideMatch m) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Cancel this connection?',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '${m.seats} ${m.seats == 1 ? 'seat will' : 'seats will'} return to the offer.${m.requestId.isEmpty ? '' : ' The request will reopen.'}',
          style: const TextStyle(fontSize: 13, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep ride'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel ride'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final student = ref.read(currentStudentProvider);
    if (student == null) return;
    setState(() => busy = true);
    try {
      await ref.read(repositoryProvider).cancelMatch(m.id, student);
      if (mounted) {
        Navigator.pop(context);
        notify(context, 'Connection cancelled. Seats returned.');
      }
    } catch (e) {
      if (mounted) notify(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final updated = (ref.watch(matchesProvider).valueOrNull ?? [])
        .where((m) => m.id == widget.match.id)
        .toList();
    final m = updated.isEmpty ? widget.match : updated.first;
    final uid = ref.watch(currentStudentProvider)?.id ?? '';
    final driver = m.driverId == uid;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            PageHeader('Your connection', back: () => Navigator.pop(context)),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoleBadge(
                    driver: driver,
                    label: driver ? 'You’re driving' : 'You’re riding',
                  ),
                  const SizedBox(height: 18),
                  RouteSummary(
                    originId: m.originId,
                    destinationId: m.destinationId,
                    subtitles: true,
                  ),
                  const SizedBox(height: 15),
                  DetailRow(
                    'Date & time',
                    '${dateLabel(m.departureAt)} · ${timeLabel(m.departureAt)}',
                  ),
                  DetailRow(
                    driver ? 'Rider' : 'Driver',
                    driver ? m.riderName : m.driverName,
                  ),
                  DetailRow('Reserved seats', '${m.seats}'),
                  DetailRow('Vehicle', m.vehicle),
                  DetailRow(
                    'Suggested fuel',
                    m.contribution == 0 ? 'Free' : '₹${m.contribution} / seat',
                  ),
                  DetailRow(
                    'Status',
                    m.status == MatchStatus.cancelled
                        ? 'Cancelled'
                        : 'Confirmed',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              'Open chat',
              icon: 'message-circle',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => ChatScreen(match: m)),
              ),
            ),
            if (m.status == MatchStatus.confirmed &&
                m.departureAt.isAfter(DateTime.now())) ...[
              const SizedBox(height: 13),
              OutlinedButton(
                onPressed: busy ? null : () => cancel(m),
                child: Text(busy ? 'Cancelling…' : 'Cancel connection'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
