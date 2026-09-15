import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// One shared pill/badge widget, replacing three independently-implemented
/// copies (_Pill in home_screen.dart, an inline badge in classes_screen.dart
/// that was missing fontWeight.w600, and _StatusPill in
/// membership_screen.dart) that had drifted out of visual sync with each
/// other.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.text, required this.isPositive, super.key});

  final String text;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPositive ? AppColors.successSurface : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isPositive ? AppColors.primary : AppColors.onBackgroundFaint,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
