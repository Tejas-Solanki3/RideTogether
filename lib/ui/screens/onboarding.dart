import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 340;
          final compact =
              constraints.maxHeight < 700 ||
              narrow ||
              MediaQuery.textScalerOf(context).scale(1) > 1.2;
          final hero = _WelcomeHero();
          final content = Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Brand(size: 36),
                    if (constraints.maxWidth >= 360) ...[
                      const Spacer(),
                      const Text(
                        'CAMPUS CARPOOL',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 26),
                if (compact)
                  SizedBox(
                    height: (constraints.maxHeight * .30).clamp(150.0, 220.0),
                    width: double.infinity,
                    child: hero,
                  )
                else
                  Expanded(child: hero),
                const SizedBox(height: 27),
                Text(
                  'Less solo.\nMore together.',
                  style: TextStyle(
                    fontSize: narrow ? 34 : 39,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.7,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Find a seat. Share your journey.\nA better campus commute starts here.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 22),
                // A Row forced all labels onto one line and overflowed at 251 px.
                const SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 14,
                    runSpacing: 12,
                    children: [
                      _Benefit('shield-check', 'Campus community'),
                      _Benefit('car-front', 'Shared seats'),
                      _Benefit('route', 'Your route'),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SwipeToStart(
                  onComplete: () =>
                      ref.read(onboardingProvider.notifier).complete(),
                ),
                const SizedBox(height: 13),
                const Center(
                  child: Text(
                    'Slide right to get started',
                    style: TextStyle(fontSize: 10, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          );
          // Small browser windows and larger text can scroll instead of clipping.
          return compact
              ? SingleChildScrollView(
                  key: const ValueKey('onboarding_scroll'),
                  child: content,
                )
              : content;
        },
      ),
    ),
  );
}

class _WelcomeHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/welcome_car.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0, .5),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          right: 16,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon('graduation-cap', size: 16),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Your campus. Your people.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  final String icon, label;
  const _Benefit(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppIcon(icon, size: 15),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

/// Draggable welcome control; screen readers receive an equivalent action.
class SwipeToStart extends StatefulWidget {
  final Future<void> Function() onComplete;
  const SwipeToStart({super.key, required this.onComplete});
  @override
  State<SwipeToStart> createState() => _SwipeToStartState();
}

class _SwipeToStartState extends State<SwipeToStart> {
  double drag = 0;
  bool busy = false;
  Future<void> finish() async {
    if (busy) return;
    setState(() => busy = true);
    HapticFeedback.mediumImpact();
    try {
      await widget.onComplete();
    } catch (error) {
      if (mounted) {
        setState(() {
          busy = false;
          drag = 0;
        });
        notify(context, friendlyError(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final end = constraints.maxWidth - 70;
      return Semantics(
        button: true,
        label: 'Get started. Swipe right or activate to sign in.',
        onTap: finish,
        child: ExcludeSemantics(
          child: GestureDetector(
            key: const ValueKey('get_started_slider'),
            onHorizontalDragUpdate: busy
                ? null
                : (event) {
                    setState(
                      () => drag = (drag + event.delta.dx)
                          .clamp(0.0, end)
                          .toDouble(),
                    );
                  },
            onHorizontalDragEnd: busy
                ? null
                : (_) {
                    if (drag >= end * .85) {
                      finish();
                    } else {
                      setState(() => drag = 0);
                    }
                  },
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: (1 - drag / (end + 1))
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      child: const Text(
                        'Get started',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    height: 68,
                    width: drag + 68,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(36),
                    ),
                  ),
                  Positioned(
                    left: drag + 4,
                    top: 4,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const AppIcon(
                                'arrow-right',
                                size: 25,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 19,
                    top: 24,
                    child: AppIcon(
                      'arrow-right',
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
