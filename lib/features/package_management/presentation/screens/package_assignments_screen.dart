import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/package_assignment_summary.dart';
import '../providers/package_providers.dart';
import '../widgets/record_payment_sheet.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');
final _priceFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

/// Personelin kendi şirketindeki paket atamalarını (isteğe bağlı üye
/// telefonuna göre arayarak) görüp ödeme kaydedebileceği ekran - backend'in
/// RecordPackageAssignmentPaymentCommand'ının gerçek dünyada kullanılabilmesi
/// için gereken tek eksik parça buydu.
class PackageAssignmentsScreen extends ConsumerStatefulWidget {
  const PackageAssignmentsScreen({super.key});

  @override
  ConsumerState<PackageAssignmentsScreen> createState() => _PackageAssignmentsScreenState();
}

class _PackageAssignmentsScreenState extends ConsumerState<PackageAssignmentsScreen> {
  final _searchController = TextEditingController();
  String? _searchPhone;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final assignmentsAsync = ref.watch(packageAssignmentsProvider(memberPhone: _searchPhone));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.packageAssignmentsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined),
            tooltip: l10n.packageManagementAssignPackageTooltip,
            onPressed: () async {
              await context.push('/staff/packages/assign');
              ref.invalidate(packageAssignmentsProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: l10n.packageAssignmentsSearchLabel,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchPhone = null);
                          },
                        ),
                ),
                onSubmitted: (value) =>
                    setState(() => _searchPhone = value.trim().isEmpty ? null : value.trim()),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(packageAssignmentsProvider),
                color: AppColors.primary,
                child: assignmentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (error, stackTrace) => _ErrorRetry(
                    message: error is ApiException ? error.message : l10n.commonError,
                    onRetry: () => ref.invalidate(packageAssignmentsProvider),
                  ),
                  data: (assignments) {
                    if (assignments.isEmpty) {
                      return ListView(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xxl * 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.receipt_long_outlined,
                                      size: 40, color: AppColors.onBackgroundFaint),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    l10n.packageAssignmentsEmptyMessage,
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
                      itemCount: assignments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => _AssignmentTile(assignment: assignments[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment});

  final PackageAssignmentSummary assignment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = assignment.status == 'Active';
    final statusText = switch (assignment.status) {
      'Active' => l10n.membershipActiveStatus,
      'Frozen' => l10n.membershipFrozenStatus,
      _ => l10n.packageAssignmentsCancelledStatus,
    };

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
                    Text(assignment.memberFullName, style: Theme.of(context).textTheme.titleMedium),
                    Text(assignment.packageName, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              StatusPill(text: statusText, isPositive: isActive),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            assignment.endDate == null
                ? _dateFormat.format(assignment.startDate)
                : '${_dateFormat.format(assignment.startDate)} – ${_dateFormat.format(assignment.endDate!)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.packageAssignmentsPaidOfPriceLabel(
                          _priceFormat.format(assignment.totalPaid),
                          _priceFormat.format(assignment.price),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (!assignment.isFullyPaid)
                        Text(
                          l10n.packageAssignmentsRemainingBalanceLabel(_priceFormat.format(assignment.remainingBalance)),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.primary),
                        ),
                    ],
                  ),
                ),
                if (!assignment.isFullyPaid)
                  OutlinedButton(
                    onPressed: () => showRecordPaymentSheet(
                      context,
                      packageAssignmentId: assignment.id,
                      remainingBalance: assignment.remainingBalance,
                    ),
                    child: Text(l10n.recordPaymentButtonLabel),
                  ),
              ],
            ),
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
