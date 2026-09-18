import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../l10n/generated/app_localizations.dart';

/// Giriş yapmış kullanıcının aktif Assignment'ı yoksa 4 içerik ekranının
/// her birinde normal (mock) içerik yerine gösterilir — bir hata değil,
/// bilgilendirici bir durumdur.
class EmptyMembershipState extends StatelessWidget {
  const EmptyMembershipState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 40, color: AppColors.onBackgroundFaint),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.membershipEmptyStateTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.membershipEmptyStateBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
