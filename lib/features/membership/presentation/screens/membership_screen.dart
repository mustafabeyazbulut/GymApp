// lib/features/membership/presentation/screens/membership_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/membership_context_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/account_frozen_state.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/empty_membership_state.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../domain/membership_summary.dart';
import '../providers/membership_provider.dart';
import '../widgets/account_info_card.dart';
import '../widgets/membership_switcher.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');
final _priceFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  bool _isTogglingFreeze = false;

  // Zaten dondurulmuşsa açmak her zaman serbest - sadece YENİ bir dondurma
  // için dondurma hakkının tükenip tükenmediğine bakılır (backend zaten
  // aynı kontrolü yapıyor, bkz. FreezePackageAssignmentCommandHandler; bu
  // sadece kullanıcıya daha önceden, düğmeyi devre dışı bırakarak
  // gösteriyor).
  bool _canFreeze(MembershipSummary summary) =>
      summary.status == MembershipStatus.frozen || summary.remainingFreezeDays == null || summary.remainingFreezeDays! > 0;

  Future<void> _toggleFreeze(MembershipSummary summary) async {
    final l10n = AppLocalizations.of(context)!;
    final isFrozen = summary.status == MembershipStatus.frozen;

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

    if (!mounted) return;
    setState(() => _isTogglingFreeze = true);
    try {
      final actions = ref.read(membershipActionsProvider.notifier);
      if (isFrozen) {
        await actions.requestUnfreeze(summary.id);
      } else {
        await actions.requestFreeze(summary.id);
      }
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    } finally {
      if (mounted) setState(() => _isTogglingFreeze = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeaderBar(title: l10n.navMembership),
      body: _buildBody(context, ref, l10n),
    );
  }

  // Hesap bilgisi (ad/telefon/e-posta, düzenle, şifre değiştir) hiçbir
  // üyeliğe bağlı değil - bu yüzden aşağıda ayrı bir async zincir olarak
  // ele alınıyor ve üyelik olsun ya da olmasın HER ZAMAN gösteriliyor (bkz.
  // AccountInfoCard). Dil/dondurma/silme/çıkış ise AppDrawer'da kalmaya
  // devam ediyor - bunlar zaten her ekranın header menü butonundan erişilebilir.
  Widget _buildBody(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentUserAsync = ref.watch(currentUserProvider);
    return currentUserAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stackTrace) => _ErrorRetry(
        message: error is AuthException ? error.localizedMessage(context) : l10n.commonError,
        onRetry: () => ref.invalidate(currentUserProvider),
      ),
      data: (currentUser) {
        if (currentUser.isAccountFrozen) {
          return const AccountFrozenState();
        }

        final membershipsAsync = ref.watch(membershipsProvider);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AccountInfoCard(user: currentUser),
            const SizedBox(height: AppSpacing.md),
            membershipsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (error, stackTrace) => _ErrorRetry(
                message: error is ApiException ? error.localizedMessage(context) : l10n.commonError,
                onRetry: () => ref.invalidate(membershipsProvider),
              ),
              data: (memberships) {
                if (memberships.isEmpty) {
                  return const EmptyMembershipState();
                }

                final selectedId = ref.watch(selectedMembershipIdProvider) ?? memberships.first.id;
                final selected = memberships.firstWhere(
                  (m) => m.id == selectedId,
                  orElse: () => memberships.first,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MembershipSwitcher(
                      label: l10n.membershipSwitcherLabel,
                      memberships: memberships,
                      selectedId: selected.id,
                      onSelect: (id) => ref.read(selectedMembershipIdProvider.notifier).select(id),
                    ),
                    _MembershipCard(summary: selected, l10n: l10n),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: _isTogglingFreeze || !_canFreeze(selected) ? null : () => _toggleFreeze(selected),
                      child: _isTogglingFreeze
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onBackground),
                            )
                          : Text(
                              selected.status == MembershipStatus.frozen
                                  ? l10n.membershipUnfreezeButton
                                  : l10n.membershipFreezeButton,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PaymentHistoryCard(packageAssignmentId: selected.id, l10n: l10n),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.membershipStaffContactNote,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.summary, required this.l10n});

  final MembershipSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.packageName, style: Theme.of(context).textTheme.titleMedium),
                      Text(summary.companyName, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                StatusPill(
                  text: summary.status == MembershipStatus.active
                      ? l10n.membershipActiveStatus
                      : l10n.membershipFrozenStatus,
                  isPositive: summary.status == MembershipStatus.active,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              summary.endDate == null
                  ? _dateFormat.format(summary.startDate)
                  : '${_dateFormat.format(summary.startDate)} – ${_dateFormat.format(summary.endDate!)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (summary.sessionCount != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.membershipSessionsRemainingLabel(summary.remainingSessions ?? 0, summary.sessionCount!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (summary.maxFreezeDays != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.membershipFreezeAllowanceLabel(summary.remainingFreezeDays ?? 0, summary.maxFreezeDays!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Text(_priceFormat.format(summary.price), style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentHistoryCard extends ConsumerWidget {
  const _PaymentHistoryCard({required this.packageAssignmentId, required this.l10n});

  final int packageAssignmentId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(membershipPaymentsProvider(packageAssignmentId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.membershipPaymentHistoryLabel, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            paymentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              ),
              error: (error, stackTrace) => Text(
                error is ApiException ? error.localizedMessage(context) : l10n.commonError,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              data: (payments) {
                if (payments.isEmpty) {
                  return Text(l10n.membershipNoPaymentsMessage, style: Theme.of(context).textTheme.bodyMedium);
                }
                return Column(
                  children: [
                    for (final entry in payments)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dateFormat.format(entry.date), style: Theme.of(context).textTheme.bodyMedium),
                            Text(_priceFormat.format(entry.amount), style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
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
