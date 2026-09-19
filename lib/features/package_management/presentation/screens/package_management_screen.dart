import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/package_summary.dart';
import '../providers/package_providers.dart';

final _priceFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

/// GymAdmin/BranchManager'ın kendi şirketinin/şubesinin paket şablolarını
/// (Süreli/Seans Bazlı, fiyat) tanımlayıp aktif/pasif yapabileceği ekran -
/// backend'de CreatePackage/SetPackageActive zaten vardı ama hiçbir mobil
/// karşılığı yoktu, bu yüzden yeni bir paket tanımlamanın tek yolu
/// Swagger/Postman'di.
class PackageManagementScreen extends ConsumerWidget {
  const PackageManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final packagesAsync = ref.watch(packagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.packageManagementTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: l10n.packageManagementAssignmentsTooltip,
            onPressed: () => context.push('/staff/packages/assignments'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.packageManagementAddButton,
            onPressed: () async {
              await context.push('/staff/packages/create');
              ref.invalidate(packagesProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(packagesProvider),
          color: AppColors.primary,
          child: packagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, stackTrace) => _ErrorRetry(
              message: error is ApiException ? error.message : l10n.commonError,
              onRetry: () => ref.invalidate(packagesProvider),
            ),
            data: (packages) {
              if (packages.isEmpty) {
                return ListView(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxl * 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_membership_outlined, size: 40, color: AppColors.onBackgroundFaint),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.packageManagementEmptyMessage,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: packages.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => _PackageTile(package: packages[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PackageTile extends ConsumerStatefulWidget {
  const _PackageTile({required this.package});

  final PackageSummary package;

  @override
  ConsumerState<_PackageTile> createState() => _PackageTileState();
}

class _PackageTileState extends ConsumerState<_PackageTile> {
  bool _isToggling = false;

  Future<void> _toggleActive(bool value) async {
    setState(() => _isToggling = true);
    try {
      await ref
          .read(packageActionsProvider.notifier)
          .setPackageActive(packageId: widget.package.id, isActive: value);
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final package = widget.package;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(package.name, style: Theme.of(context).textTheme.titleMedium)),
                    StatusPill(
                      text: package.isActive
                          ? l10n.companyManagementActiveBadge
                          : l10n.companyManagementInactiveBadge,
                      isPositive: package.isActive,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  package.isDuration
                      ? l10n.packageDurationSubtitle(package.durationDays ?? 0)
                      : l10n.packageSessionSubtitle(package.sessionCount ?? 0),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_priceFormat.format(package.price), style: Theme.of(context).textTheme.titleSmall),
                if (package.maxFreezeDays != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.packageMaxFreezeDaysSubtitle(package.maxFreezeDays!),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onBackgroundFaint),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _isToggling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : Switch(
                  value: package.isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: _toggleActive,
                ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
