import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/phone_number_field.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/package_assignment_summary.dart';
import '../providers/package_providers.dart';
import '../widgets/record_payment_sheet.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');
// Tutarlar uygulamanın diline göre biçimlenir (tr: ₺1.234,50, en: ₺1,234.50).
String _price(BuildContext context, num amount) => formatMoney(amount, 'TRY', Localizations.localeOf(context));

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
  final _searchFormKey = GlobalKey<FormState>();
  // E.164 biçiminde (bkz. PhoneNumberField) - null ise tüm atamalar listelenir.
  String? _searchPhone;

  void _search(String? phone) {
    // Geçersiz bir numarayla arama yapmak yerine alanın altında hatayı göster.
    if (!_searchFormKey.currentState!.validate()) return;
    setState(() => _searchPhone = phone);
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
              child: Form(
                key: _searchFormKey,
                child: PhoneNumberField(
                  labelText: l10n.packageAssignmentsSearchLabel,
                  isRequired: false,
                  clearable: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(packageAssignmentsProvider),
                color: AppColors.primary,
                child: assignmentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (error, stackTrace) => _ErrorRetry(
                    message: error is ApiException ? error.localizedMessage(context) : l10n.commonError,
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

class _AssignmentTile extends ConsumerWidget {
  const _AssignmentTile({required this.assignment});

  final PackageAssignmentSummary assignment;

  Future<void> _confirmAndCancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.packageAssignmentsCancelConfirmTitle),
        content: Text(l10n.packageAssignmentsCancelConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountDeletionCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.packageAssignmentsCancelConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(packageActionsProvider.notifier).cancelPackageAssignment(assignment.id);
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  Future<void> _checkIn(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(packageActionsProvider.notifier).recordGeneralCheckIn(assignment.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.packageAssignmentsCheckInSuccessMessage)));
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  // Üye kendi paketini Üyelik ekranından zaten dondurup açabiliyor - bu,
  // telefonla arayıp "üyeliğimi dondurun" diyen ama uygulamayı kullanmayan/
  // bilmeyen bir üye için personelin AYNI işlemi onun adına yapabilmesi.
  Future<void> _toggleFreeze(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final isFrozen = assignment.status == 'Frozen';

    if (!isFrozen) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.membershipFreezeConfirmTitle),
          content: Text(l10n.membershipFreezeConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.accountDeletionCancelButton),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.membershipFreezeConfirmButton),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final actions = ref.read(packageActionsProvider.notifier);
      if (isFrozen) {
        await actions.unfreezePackageAssignment(assignment.id);
      } else {
        await actions.freezePackageAssignment(assignment.id);
      }
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = assignment.status == 'Active';
    final isFrozen = assignment.status == 'Frozen';
    final isCancelled = assignment.status == 'Cancelled';
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
              if (!isCancelled)
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                  tooltip: l10n.packageAssignmentsCancelButton,
                  onPressed: () => _confirmAndCancel(context, ref),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.endDate == null
                      ? _dateFormat.format(assignment.startDate)
                      : '${_dateFormat.format(assignment.startDate)} – ${_dateFormat.format(assignment.endDate!)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
                ),
              ),
              if (assignment.remainingSessions != null)
                Text(
                  l10n.packageAssignmentsRemainingSessionsLabel(assignment.remainingSessions!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
                ),
            ],
          ),
          if (assignment.maxFreezeDays != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.membershipFreezeAllowanceLabel(assignment.remainingFreezeDays ?? 0, assignment.maxFreezeDays!),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
            ),
          ],
          if (!isCancelled) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (isActive)
                  OutlinedButton.icon(
                    onPressed: () => _checkIn(context, ref),
                    icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
                    label: Text(l10n.packageAssignmentsCheckInButton),
                  ),
                OutlinedButton.icon(
                  onPressed: (isActive && assignment.remainingFreezeDays == 0)
                      ? null
                      : () => _toggleFreeze(context, ref),
                  icon: Icon(isFrozen ? Icons.play_circle_outline : Icons.pause_circle_outline, size: 18),
                  label: Text(isFrozen ? l10n.membershipUnfreezeButton : l10n.membershipFreezeButton),
                ),
              ],
            ),
          ],
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
                          _price(context, assignment.totalPaid),
                          _price(context, assignment.price),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (!assignment.isFullyPaid)
                        Text(
                          l10n.packageAssignmentsRemainingBalanceLabel(_price(context, assignment.remainingBalance)),
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
