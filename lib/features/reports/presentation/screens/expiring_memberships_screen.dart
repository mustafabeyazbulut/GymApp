import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/expiring_membership.dart';
import '../providers/reports_providers.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');
const _dayFilters = [7, 30, 90, 365];

class ExpiringMembershipsScreen extends ConsumerStatefulWidget {
  const ExpiringMembershipsScreen({super.key});

  @override
  ConsumerState<ExpiringMembershipsScreen> createState() => _ExpiringMembershipsScreenState();
}

class _ExpiringMembershipsScreenState extends ConsumerState<ExpiringMembershipsScreen> {
  int _daysAhead = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final membershipsAsync = ref.watch(expiringMembershipsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsExpiringMembershipsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final days in _dayFilters)
                  ChoiceChip(
                    label: Text(l10n.reportsExpiringMembershipsFilterDays(days)),
                    selected: _daysAhead == days,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() => _daysAhead = days);
                      ref.read(expiringMembershipsProvider.notifier).setDaysAhead(days);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: membershipsAsync.when(
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
                        onPressed: () => ref.invalidate(expiringMembershipsProvider),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (memberships) {
                if (memberships.isEmpty) {
                  return ListView(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl * 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_busy_outlined, size: 40, color: AppColors.onBackgroundFaint),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                l10n.reportsExpiringMembershipsEmptyMessage,
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
                  itemCount: memberships.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => _MembershipTile(l10n: l10n, membership: memberships[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipTile extends StatelessWidget {
  const _MembershipTile({required this.l10n, required this.membership});

  final AppLocalizations l10n;
  final ExpiringMembership membership;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = membership.isAlreadyExpired ? AppColors.error : AppColors.primary;
    final statusText = membership.isAlreadyExpired
        ? l10n.reportsExpiringMembershipsAlreadyExpiredLabel(membership.daysRemaining.abs())
        : l10n.reportsExpiringMembershipsDaysRemainingLabel(membership.daysRemaining);

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
                    Text(membership.memberFullName, style: textTheme.titleMedium),
                    Text(membership.packageName, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              Text(membership.memberPhone, style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint)),
            ],
          ),
          if (membership.branchName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              membership.branchName!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _dateFormat.format(membership.endDate),
                style: textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
              ),
              Text(statusText, style: textTheme.bodyLarge?.copyWith(color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}
