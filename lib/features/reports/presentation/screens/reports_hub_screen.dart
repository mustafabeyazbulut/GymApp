import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// StaffManagement için raporlama girişleri - GymAdmin'in en çok ihtiyaç
/// duyduğu üç rapora (gelir, bekleyen bakiye, süresi yaklaşan üyelik) tek
/// yerden erişim sağlar.
class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsHubTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _ReportEntryTile(
            icon: Icons.payments_outlined,
            label: l10n.reportsHubRevenueLabel,
            description: l10n.reportsHubRevenueDescription,
            onTap: () => context.push('/staff/reports/revenue'),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReportEntryTile(
            icon: Icons.account_balance_wallet_outlined,
            label: l10n.reportsHubOutstandingBalancesLabel,
            description: l10n.reportsHubOutstandingBalancesDescription,
            onTap: () => context.push('/staff/reports/outstanding-balances'),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReportEntryTile(
            icon: Icons.event_busy_outlined,
            label: l10n.reportsHubExpiringMembershipsLabel,
            description: l10n.reportsHubExpiringMembershipsDescription,
            onTap: () => context.push('/staff/reports/expiring-memberships'),
          ),
        ],
      ),
    );
  }
}

class _ReportEntryTile extends StatelessWidget {
  const _ReportEntryTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          leading: Icon(icon, color: AppColors.primary),
          title: Text(label, style: textTheme.titleMedium),
          subtitle: Text(description, style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.onBackgroundFaint),
          onTap: onTap,
        ),
      ),
    );
  }
}
