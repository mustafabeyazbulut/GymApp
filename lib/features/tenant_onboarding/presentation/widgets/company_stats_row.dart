import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Bir şirketin şube/personel/üye sayılarını tek satırda özetler - hem
/// firma listesindeki her satırda hem de firma detay ekranında aynı
/// özet görünsün diye ortak bir widget olarak çıkarıldı.
class CompanyStatsRow extends StatelessWidget {
  const CompanyStatsRow({
    super.key,
    required this.branchCount,
    required this.gymAdminCount,
    required this.branchManagerCount,
    required this.trainerCount,
    required this.memberCount,
  });

  final int branchCount;
  final int gymAdminCount;
  final int branchManagerCount;
  final int trainerCount;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parts = [
      l10n.companyManagementBranchCount(branchCount),
      l10n.companyManagementGymAdminCount(gymAdminCount),
      l10n.companyManagementBranchManagerCount(branchManagerCount),
      l10n.companyManagementTrainerCount(trainerCount),
      l10n.companyManagementMemberCount(memberCount),
    ];
    return Text(
      parts.join(' • '),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
    );
  }
}
