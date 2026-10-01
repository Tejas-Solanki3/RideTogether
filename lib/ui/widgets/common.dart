import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/models.dart';
import '../theme.dart';

class Brand extends StatelessWidget {
  final bool compact;
  const Brand({super.key, this.compact = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset(
        'assets/svg/logo.svg',
        width: compact ? 32 : 38,
        height: compact ? 32 : 38,
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          'RideTogether',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 18 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
      ),
    ],
  );
}

class Avatar extends StatelessWidget {
  final String name, asset;
  final double size;
  const Avatar({
    super.key,
    required this.name,
    this.asset = '',
    this.size = 42,
  });
  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join();
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: asset.isNotEmpty
                ? Image.asset(
                    'assets/avatars/$asset.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: AppColors.sage,
                      child: Center(child: Text(initials)),
                    ),
                  )
                : ColoredBox(
                    color: AppColors.sage,
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: size * .32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class RoleBadge extends StatelessWidget {
  final bool driver;
  final String? label;
  const RoleBadge({super.key, required this.driver, this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: driver ? AppColors.sage : AppColors.blueLight,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          driver ? Icons.drive_eta_outlined : Icons.person_outline_rounded,
          size: 13,
          color: driver ? AppColors.green : AppColors.blue,
        ),
        const SizedBox(width: 5),
        Text(
          label ?? (driver ? 'Driver' : 'Rider'),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: driver ? AppColors.green : AppColors.blue,
          ),
        ),
      ],
    ),
  );
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = AppColors.green});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      letterSpacing: 1.7,
      fontWeight: FontWeight.w800,
      color: color,
    ),
  );
}

class LiveDot extends StatelessWidget {
  final String label;
  const LiveDot({super.key, this.label = 'Live updates'});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.green,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(padding: padding, child: child),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading, arrow;
  final IconData? icon;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.arrow = true,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 17),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label)),
        if (arrow && !loading) ...[
          const SizedBox(width: 13),
          const Icon(Icons.arrow_forward_rounded, size: 17),
        ],
      ],
    ),
  );
}

class SelectionPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const SelectionPill({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.ink : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.ink,
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const InfoItem(
    this.icon,
    this.text, {
    super.key,
    this.color = AppColors.muted,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

class RouteRow extends StatelessWidget {
  final CampusPlace origin, destination;
  final bool vertical;
  const RouteRow({
    super.key,
    required this.origin,
    required this.destination,
    this.vertical = false,
  });
  Widget dot(bool first) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      color: first ? Colors.white : AppColors.ink,
      shape: first ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: first ? null : BorderRadius.circular(2),
      border: Border.all(color: AppColors.ink, width: 2),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Column(
              children: [
                dot(true),
                Container(width: 1, height: 33, color: AppColors.line),
                dot(false),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  origin.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  origin.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 13),
                Text(
                  destination.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  destination.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        dot(true),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            origin.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: AppColors.muted,
          ),
        ),
        dot(false),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            destination.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.route_outlined,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Surface(
    child: SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.green),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.7),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}

class ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback retry;
  const ErrorState({super.key, required this.error, required this.retry});
  @override
  Widget build(BuildContext context) => EmptyState(
    title: 'Let’s try that again',
    subtitle: friendlyError(error),
    icon: Icons.cloud_off_outlined,
    action: OutlinedButton.icon(
      onPressed: retry,
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text('Retry'),
    ),
  );
}

String friendlyError(Object e) {
  if (e is RideException) return e.message;
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' =>
        'That email and password didn’t match. Please try again.',
      'email-already-in-use' =>
        'An account already exists for this email. Try signing in.',
      'weak-password' =>
        'Choose a stronger password with at least 6 characters.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment before trying again.',
      'network-request-failed' => 'Check your connection and try again.',
      'operation-not-allowed' =>
        'Enable Email/Password sign-in in your Firebase console.',
      _ => e.message ?? 'Something went wrong. Please try again.',
    };
  }
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return 'You don’t have access yet. Verify your campus email and check the Firestore rules.';
    }
    if (e.code == 'failed-precondition') {
      return 'A Firestore index is missing. Deploy firestore.indexes.json from the project.';
    }
    if (e.code == 'unavailable') {
      return 'Connection unavailable. Please try again when you’re online.';
    }
  }
  return 'Something went wrong. Please try again.';
}

void notify(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.red : AppColors.ink,
    ),
  );
}

Future<T?> openPanel<T>(
  BuildContext context,
  Widget child, {
  double width = 540,
}) {
  if (MediaQuery.sizeOf(context).width < 640) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .94,
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: child,
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: MediaQuery.sizeOf(context).height - 56,
        ),
        child: child,
      ),
    ),
  );
}

class PanelHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  const PanelHeader(this.title, {super.key, this.leading});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (leading != null) ...[leading!, const SizedBox(width: 12)],
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      IconButton(
        tooltip: 'Close',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded, size: 20),
      ),
    ],
  );
}

class DetailTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const DetailTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.green),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}
