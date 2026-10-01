import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../theme.dart';
import 'common.dart';

class RideCard extends ConsumerWidget {
  final Ride ride;
  final bool bestMatch;
  final VoidCallback onView;
  const RideCard({
    super.key,
    required this.ride,
    required this.onView,
    this.bestMatch = false,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedRidesProvider).contains(ride.id);
    final driver = ride.kind == RideKind.offer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final small = constraints.maxWidth < 470;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(
                      name: ride.ownerName,
                      asset: ride.ownerAvatar,
                      size: 43,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ride.ownerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (!small) ...[
                                const SizedBox(width: 9),
                                RoleBadge(driver: driver),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            driver ? ride.vehicle : 'Looking for a campus ride',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ride.contribution == 0
                              ? (driver ? 'Free' : '₹0')
                              : '₹${ride.contribution}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.7,
                          ),
                        ),
                        Text(
                          driver ? 'per seat' : 'suggested / seat',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      tooltip: saved ? 'Unsave ride' : 'Save ride',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 36,
                      ),
                      padding: const EdgeInsets.all(6),
                      onPressed: () =>
                          ref.read(savedRidesProvider.notifier).toggle(ride.id),
                      icon: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: saved ? AppColors.green : AppColors.muted,
                      ),
                    ),
                  ],
                ),
                if (small) ...[
                  const SizedBox(height: 10),
                  RoleBadge(driver: driver),
                ],
                const SizedBox(height: 20),
                RouteRow(
                  origin: ride.origin,
                  destination: ride.destination,
                  vertical: small,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 14),
                if (small) ...[
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      InfoItem(
                        Icons.calendar_today_outlined,
                        dateLabel(ride.departureAt),
                      ),
                      InfoItem(
                        Icons.schedule_rounded,
                        timeLabel(ride.departureAt),
                      ),
                      InfoItem(
                        Icons.airline_seat_recline_normal_rounded,
                        '${ride.availableSeats} ${ride.availableSeats == 1 ? 'seat' : 'seats'} ${driver ? 'left' : 'needed'}',
                        color: ride.availableSeats == 1 && driver
                            ? AppColors.green
                            : AppColors.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (bestMatch)
                        const Expanded(child: _BestMatch())
                      else
                        const Spacer(),
                      PrimaryButton(
                        label: driver ? 'View ride' : 'View request',
                        onPressed: onView,
                      ),
                    ],
                  ),
                ] else
                  Row(
                    children: [
                      InfoItem(
                        Icons.calendar_today_outlined,
                        dateLabel(ride.departureAt),
                      ),
                      const SizedBox(width: 15),
                      InfoItem(
                        Icons.schedule_rounded,
                        timeLabel(ride.departureAt),
                      ),
                      const SizedBox(width: 15),
                      InfoItem(
                        Icons.airline_seat_recline_normal_rounded,
                        '${ride.availableSeats} ${ride.availableSeats == 1 ? 'seat' : 'seats'} ${driver ? 'left' : 'needed'}',
                        color: ride.availableSeats == 1 && driver
                            ? AppColors.green
                            : AppColors.muted,
                      ),
                      const Spacer(),
                      PrimaryButton(
                        label: driver ? 'View ride' : 'View request',
                        onPressed: onView,
                      ),
                    ],
                  ),
                if (bestMatch && !small) ...[
                  const SizedBox(height: 11),
                  const _BestMatch(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BestMatch extends StatelessWidget {
  const _BestMatch();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.bolt_rounded, size: 13, color: AppColors.green),
      SizedBox(width: 4),
      Flexible(
        child: Text(
          'Earliest on your route',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.green,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
