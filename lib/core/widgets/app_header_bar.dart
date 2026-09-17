import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_shell.dart';

/// The shared top bar for every main shell screen (Home, Classes, Progress,
/// Membership) — a menu button opening [AppDrawer], a centered title, a
/// notification bell, and a thin accent-line underneath. Screens that need
/// their own `bottom` widget (filters, tabs) keep that in the body instead,
/// since an `AppBar` only has room for one `bottom`.
class AppHeaderBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeaderBar({required this.title, super.key});

  final String title;

  static const _accentLineHeight = 2.0;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + _accentLineHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasUnreadNotifications = ref.watch(hasUnreadNotificationsProvider);

    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(title),
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: _HeaderIconButton(
          icon: Icons.menu,
          tooltip: l10n.drawerOpenMenuTooltip,
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: _HeaderIconButton(
            icon: Icons.notifications_outlined,
            tooltip: l10n.notificationsTitle,
            showDot: hasUnreadNotifications,
            onPressed: () => context.push('/notifications'),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_accentLineHeight),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          height: _accentLineHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.background,
                AppColors.primary.withValues(alpha: 0.55),
                AppColors.background,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A circular, filled icon button used for the header's menu/notification
/// actions — an outline-icon-on-flat-chip look distinct from Material's
/// default flat AppBar icon buttons.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showDot = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, size: 19, color: AppColors.onBackground),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceElevated,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        if (showDot)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: AppColors.surfaceElevated, width: 2)),
              ),
            ),
          ),
      ],
    );
  }
}
