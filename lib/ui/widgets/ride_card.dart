import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'common.dart';
import '../screens/ride_details.dart';

class RideCard extends ConsumerWidget {
  final Ride ride;
  const RideCard(this.ride, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedRidesProvider).contains(ride.id),
        offer = ride.kind == RideKind.offer;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(name: ride.ownerName, asset: ride.ownerAvatar, size: 43),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.ownerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        offer ? ride.vehicle : 'Looking for a campus lift',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: saved ? 'Unsave ride' : 'Save ride',
                  onPressed: () =>
                      ref.read(savedRidesProvider.notifier).toggle(ride.id),
                  icon: AppIcon(
                    'bookmark',
                    size: 20,
                    color: saved ? Colors.white : Colors.black,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: saved
                        ? Colors.black
                        : AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: const EdgeInsets.all(10),
                ),
              ],
            ),
            const SizedBox(height: 15),
            RoleBadge(driver: offer),
            const SizedBox(height: 14),
            RouteSummary(
              originId: ride.originId,
              destinationId: ride.destinationId,
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                Expanded(
                  child: Meta('calendar-days', dateLabel(ride.departureAt)),
                ),
                Expanded(child: Meta('clock-3', timeLabel(ride.departureAt))),
                Expanded(
                  child: Meta(
                    'armchair',
                    '${ride.availableSeats} ${offer ? 'seats left' : 'needed'}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.contribution == 0
                            ? 'Free'
                            : '₹${ride.contribution}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.7,
                        ),
                      ),
                      Text(
                        offer
                            ? 'per seat · suggested fuel'
                            : 'suggested per seat',
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 146,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RideDetailsScreen(rideId: ride.id),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          offer ? 'View ride' : 'View request',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                        const AppIcon(
                          'arrow-right',
                          size: 16,
                          color: Colors.white,
                        ),
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
