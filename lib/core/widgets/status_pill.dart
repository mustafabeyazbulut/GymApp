import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Birbirinden görsel olarak farklılaşmış üç bağımsız uygulamanın
/// (home_screen.dart içindeki _Pill, classes_screen.dart içinde
/// fontWeight.w600 eksik olan satır içi rozet ve membership_screen.dart
/// içindeki _StatusPill) yerini alan tek, ortak pill/rozet widget'ı.
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
