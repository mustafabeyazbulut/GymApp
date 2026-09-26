import 'package:flutter/material.dart';
import '../../features/membership/domain/membership_summary.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Geçerli paketi olmayan üyeye ders/içerik listesi yerine gösterilen boş
/// durum - backend bu üyeye listeyi boş döndüğü için "henüz ders yok" yerine
/// asıl nedeni söyler: hiç paketi yok ya da paketi geçerli değil (donmuş,
/// süresi dolmuş, hakkı bitmiş). EmptyMembershipState ile aynı görsel dil.
class PackageStatusEmptyState extends StatelessWidget {
  const PackageStatusEmptyState({required this.availability, super.key});

  /// [MembershipAvailabilityState.valid] için kullanılmaz - çağıran o durumda
  /// kendi listesini/boş mesajını gösterir.
  final MembershipAvailability availability;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasNoPackage = availability.state == MembershipAvailabilityState.none;
    final title = hasNoPackage ? l10n.packageStatusNoPackageTitle : l10n.packageStatusInvalidTitle;
    final body = hasNoPackage
        ? l10n.packageStatusNoPackageBody
        : switch (availability.reason) {
            PackageValidity.frozen => l10n.packageStatusInvalidFrozen,
            PackageValidity.expired => l10n.packageStatusInvalidExpired,
            PackageValidity.noSessionsLeft => l10n.packageStatusInvalidNoSessions,
            PackageValidity.valid || null => l10n.packageStatusNoPackageBody,
          };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasNoPackage ? Icons.storefront_outlined : Icons.event_busy_outlined,
              size: 40,
              color: AppColors.onBackgroundFaint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
