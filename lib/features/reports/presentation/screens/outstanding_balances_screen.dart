import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/outstanding_balance.dart';
import '../providers/reports_providers.dart';

// Tutarlar uygulamanın diline göre biçimlenir (tr: ₺1.234,50, en: ₺1,234.50).
String _price(BuildContext context, num amount) => formatMoney(amount, 'TRY', Localizations.localeOf(context));

class OutstandingBalancesScreen extends ConsumerWidget {
  const OutstandingBalancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balancesAsync = ref.watch(outstandingBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsOutstandingBalancesTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(outstandingBalancesProvider.notifier).refresh(),
        color: AppColors.primary,
        child: balancesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException ? error.localizedMessage(context) : l10n.commonError,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(outstandingBalancesProvider),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
          data: (balances) {
            if (balances.isEmpty) {
              return ListView(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxl * 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              size: 40, color: AppColors.onBackgroundFaint),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.reportsOutstandingBalancesEmptyMessage,
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
              itemCount: balances.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _BalanceTile(l10n: l10n, balance: balances[index]),
            );
          },
        ),
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.l10n, required this.balance});

  final AppLocalizations l10n;
  final OutstandingBalance balance;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(balance.memberFullName, style: textTheme.titleMedium),
                    Text(balance.packageName, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              Text(balance.memberPhone, style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint)),
            ],
          ),
          if (balance.branchName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              balance.branchName!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.packageAssignmentsPaidOfPriceLabel(
                    _price(context, balance.totalPaid),
                    _price(context, balance.price),
                  ),
                  style: textTheme.bodyMedium,
                ),
                Text(
                  l10n.packageAssignmentsRemainingBalanceLabel(_price(context, balance.remainingBalance)),
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
