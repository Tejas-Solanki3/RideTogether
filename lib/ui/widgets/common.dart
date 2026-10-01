import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/models.dart';
import '../theme.dart';

const monochrome = ColorFilter.matrix([
  .2126,
  .7152,
  .0722,
  0,
  0,
  .2126,
  .7152,
  .0722,
  0,
  0,
  .2126,
  .7152,
  .0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  const AppIcon(
    this.name, {
    super.key,
    this.size = 22,
    this.color = AppColors.ink,
  });
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    excludeFromSemantics: true,
  );
}

class Brand extends StatelessWidget {
  final double size;
  const Brand({super.key, this.size = 34});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset(
        'assets/svg/logo.svg',
        width: size,
        height: size,
        excludeFromSemantics: true,
      ),
      const SizedBox(width: 10),
      const Text(
        'RideTogether',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -.65,
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
    this.size = 44,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: ClipOval(
      child: ColoredBox(
        color: AppColors.surface,
        child: asset.isNotEmpty
            ? ColorFiltered(
                colorFilter: monochrome,
                child: Image.asset(
                  'assets/avatars/$asset.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => _initials(),
                ),
              )
            : _initials(),
      ),
    ),
  );
  Widget _initials() => Center(
    child: Text(
      name
          .trim()
          .split(' ')
          .where((s) => s.isNotEmpty)
          .take(2)
          .map((s) => s[0])
          .join(),
      style: TextStyle(fontSize: size * .32, fontWeight: FontWeight.w800),
    ),
  );
}

class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final bool border;
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
    this.radius = 22,
    this.border = false,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border ? const BorderSide(color: AppColors.line) : BorderSide.none,
    ),
    child: Padding(padding: padding, child: child),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy, arrow;
  final String? icon;
  const PrimaryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.busy = false,
    this.arrow = true,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else ...[
            if (icon != null) ...[
              AppIcon(icon!, size: 19, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (arrow) ...[
              const SizedBox(width: 12),
              const AppIcon('arrow-right', size: 19, color: Colors.white),
            ],
          ],
        ],
      ),
    ),
  );
}

class RoundButton extends StatelessWidget {
  final String icon, label;
  final VoidCallback? onPressed;
  final Color background;
  final double size;
  const RoundButton(
    this.icon, {
    super.key,
    required this.label,
    required this.onPressed,
    this.background = Colors.white,
    this.size = 48,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: IconButton(
      tooltip: label,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      icon: AppIcon(icon, size: 22),
    ),
  );
}

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? back;
  final Widget? trailing;
  const PageHeader(this.title, {super.key, this.back, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
    child: Row(
      children: [
        if (back != null)
          RoundButton('arrow-left', label: 'Back', onPressed: back)
        else
          const SizedBox(width: 48),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
        ),
        trailing ?? const SizedBox(width: 48),
      ],
    ),
  );
}

class RoleBadge extends StatelessWidget {
  final bool driver;
  final String? label;
  const RoleBadge({super.key, required this.driver, this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: driver ? Colors.black : AppColors.surface,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          driver ? 'car-front' : 'user-round',
          size: 13,
          color: driver ? Colors.white : Colors.black,
        ),
        const SizedBox(width: 5),
        Text(
          label ?? (driver ? 'Driver' : 'Rider'),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: driver ? Colors.white : Colors.black,
          ),
        ),
      ],
    ),
  );
}

class Meta extends StatelessWidget {
  final String icon, label;
  const Meta(this.icon, this.label, {super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppIcon(icon, size: 15, color: AppColors.muted),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class DetailRow extends StatelessWidget {
  final String label, value;
  const DetailRow(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class RouteSummary extends StatelessWidget {
  final String originId, destinationId;
  final bool subtitles;
  const RouteSummary({
    super.key,
    required this.originId,
    required this.destinationId,
    this.subtitles = false,
  });
  @override
  Widget build(BuildContext context) {
    Widget stop(String label, CampusPlace p, String icon) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(child: AppIcon(icon, size: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitles)
                Text(
                  p.subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
            ],
          ),
        ),
      ],
    );
    return Surface(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        children: [
          stop('Pick up', CampusPlace.byId(originId), 'navigation'),
          Padding(
            padding: const EdgeInsets.only(left: 19),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 1, height: 19, color: AppColors.line),
            ),
          ),
          stop('Destination', CampusPlace.byId(destinationId), 'map-pin'),
        ],
      ),
    );
  }
}

class SelectTile extends StatelessWidget {
  final String label, value, icon;
  final String? subtitle;
  final VoidCallback onTap;
  const SelectTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                AppIcon(icon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<String?> choosePlace(
  BuildContext context, {
  required String title,
  required String selected,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (ctx) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 15),
        ...CampusPlace.all.map(
          (p) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            minTileHeight: 64,
            leading: const AppIcon('map-pin'),
            title: Text(
              p.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              p.subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            trailing: p.id == selected
                ? const AppIcon('check', size: 20)
                : null,
            onTap: () => Navigator.pop(ctx, p.id),
          ),
        ),
      ],
    ),
  ),
);

class EmptyState extends StatelessWidget {
  final String title, body, icon;
  final Widget? action;
  const EmptyState(
    this.title,
    this.body, {
    super.key,
    this.icon = 'search',
    this.action,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 22),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(child: AppIcon(icon, size: 28)),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
            height: 1.7,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 22), action!],
      ],
    ),
  );
}

void notify(BuildContext context, String text) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

String friendlyError(Object e) {
  if (e is RideException) return e.message;
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' =>
        'That email and password didn’t match. Please try again.',
      'email-already-in-use' =>
        'This email already has an account. Try signing in.',
      'weak-password' => 'Choose a password with at least 6 characters.',
      'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
      'network-request-failed' => 'Check your connection and try again.',
      'operation-not-allowed' =>
        'Enable Email/Password authentication in Firebase.',
      _ => e.message ?? 'Please try again.',
    };
  }
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return 'Verify your campus email and check access rules.';
    }
    if (e.code == 'failed-precondition') {
      return 'Deploy the supplied Firestore indexes.';
    }
    if (e.code == 'unavailable') {
      return 'You’re offline. Connect before reserving a seat.';
    }
  }
  return 'Something went wrong. Please try again.';
}
