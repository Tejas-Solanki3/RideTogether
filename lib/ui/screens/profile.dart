import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  Future<void> signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(repositoryProvider).signOut();
      ref.read(tabProvider.notifier).state = AppTab.find;
      ref.read(requestContextProvider.notifier).state = null;
    } catch (e) {
      if (context.mounted) notify(context, friendlyError(e));
    }
  }

  void info(BuildContext context, String title, String body) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 23),
              PrimaryButton('Got it', onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      );
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProvider);
    if (student == null) return const SizedBox();
    final demo = ref.watch(repositoryProvider).isDemo;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const Brand(),
        const SizedBox(height: 30),
        Text('Your corner.', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Surface(
          child: Row(
            children: [
              Avatar(name: student.name, asset: student.avatar, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.email,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      demo ? 'LOCAL DEMO ACCOUNT' : 'EMAIL VERIFIED',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Surface(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          child: Column(
            children: [
              _Item(
                'graduation-cap',
                'Your campus',
                'Greenfield University',
                () => info(
                  context,
                  'Your campus',
                  'Greenfield University is a fictional sample campus. Locations and profiles are demonstration data. The map is illustrative, not navigation.',
                ),
              ),
              const Divider(height: 1),
              _Item(
                'shield-check',
                'Ride responsibly',
                'Simple things make a safer ride.',
                () => info(
                  context,
                  'Good company. Safer journeys.',
                  'Confirm your pickup in private chat. Use seat belts. Only offer seats you can safely provide. Do not share personal information publicly. This app does not provide emergency assistance or verify driving licences.',
                ),
              ),
              const Divider(height: 1),
              _Item(
                'lock-keyhole',
                'Your data',
                'You stay in control.',
                () => info(
                  context,
                  'Your data',
                  demo
                      ? 'Demo rides, matches and chat are saved on this device. No real password is stored. Reset the local demo below to clear its data. No other person is online.'
                      : 'Your Firebase project stores campus posts and private participant-only matches and chat. Public ride cards do not expose your email. Account deletion and retention policies must be configured by your campus administrator.',
                ),
              ),
              const Divider(height: 1),
              _Item(
                'circle-help',
                'About RideTogether',
                'Made for campus, not taxi fares.',
                () => info(
                  context,
                  'RideTogether',
                  'A Flutter campus carpool prototype, currently developed in Chrome. Post an offer or request, find a compatible ride, reserve seats and coordinate your pickup. Fuel contributions are suggested amounts; the app does not collect payments.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (demo) ...[
          OutlinedButton(
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text(
                    'Reset local demo?',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  content: const Text(
                    'Your demo posts, connections and messages will be replaced by the sample campus. You will be signed out.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Keep my data'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset demo'),
                    ),
                  ],
                ),
              );
              if (yes == true) {
                try {
                  await ref.read(savedRidesProvider.notifier).clear();
                  await ref.read(repositoryProvider).resetDemo();
                  ref.read(tabProvider.notifier).state = AppTab.find;
                } catch (e) {
                  if (context.mounted) notify(context, friendlyError(e));
                }
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon('rotate-ccw', size: 18),
                SizedBox(width: 9),
                Text('Reset local demo'),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          'Sign out',
          icon: 'log-out',
          arrow: false,
          onPressed: () => signOut(context, ref),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'RIDETOGETHER / FLUTTER\nYOUR CAMPUS, CONNECTED.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: AppColors.muted,
              height: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final String icon, title, subtitle;
  final VoidCallback tap;
  const _Item(this.icon, this.title, this.subtitle, this.tap);
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
    leading: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: AppIcon(icon, size: 20)),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 9, color: AppColors.muted),
    ),
    trailing: const AppIcon('arrow-up-right', size: 17),
    onTap: tap,
  );
}
