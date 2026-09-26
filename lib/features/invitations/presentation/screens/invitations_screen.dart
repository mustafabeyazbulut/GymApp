import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/invitation.dart';
import '../providers/invitations_provider.dart';

final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

/// Kullanıcıya gelen bekleyen davetler (ana senaryo §3.4, §4.1): firma
/// yöneticiliği, personel görevi ya da paket. Uygulama içinde tek dokunuşla
/// onaylanır/reddedilir; SMS'teki kodu kullanmak isteyenler için "Kodla
/// onayla" ikincil yol olarak ConfirmInvitationScreen'e gider.
class InvitationsScreen extends ConsumerStatefulWidget {
  const InvitationsScreen({super.key});

  @override
  ConsumerState<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends ConsumerState<InvitationsScreen> {
  // Onay/ret sürerken aynı karttaki butonlar kilitlenir (çift dokunuş).
  int? _busyInvitationId;

  @override
  void initState() {
    super.initState();
    // Liste menü rozeti için zaten yüklenmişse ekrana her girişte tazelenir;
    // hiç yüklenmemişse ilk izlemede zaten çekilecek.
    if (ref.exists(myInvitationsProvider)) {
      Future.microtask(() {
        if (mounted) ref.invalidate(myInvitationsProvider);
      });
    }
  }

  Future<void> _accept(Invitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    await _run(invitation, () => ref.read(invitationActionsProvider.notifier).accept(invitation),
        l10n.invitationsAcceptedMessage);
  }

  Future<void> _reject(Invitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.invitationsRejectConfirmTitle),
        content: Text(l10n.invitationsRejectConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountDeletionCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.invitationsRejectButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(invitation, () => ref.read(invitationActionsProvider.notifier).reject(invitation),
        l10n.invitationsRejectedMessage);
  }

  Future<void> _run(Invitation invitation, Future<void> Function() action, String successMessage) async {
    setState(() => _busyInvitationId = invitation.id);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    } finally {
      if (mounted) setState(() => _busyInvitationId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invitationsAsync = ref.watch(myInvitationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invitationsTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(myInvitationsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              ...invitationsAsync.when(
                loading: () => [
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                ],
                error: (error, stackTrace) => [
                  _ErrorState(
                    message: error is ApiException ? error.localizedMessage(context) : l10n.commonError,
                    onRetry: () => ref.invalidate(myInvitationsProvider),
                  ),
                ],
                data: (invitations) => invitations.isEmpty
                    ? [const _EmptyState()]
                    : [
                        for (final invitation in invitations)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _InvitationCard(
                              invitation: invitation,
                              isBusy: _busyInvitationId == invitation.id,
                              onAccept: () => _accept(invitation),
                              onReject: () => _reject(invitation),
                            ),
                          ),
                      ],
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/confirm-invitation'),
                  child: Text(l10n.invitationsConfirmWithCode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  final Invitation invitation;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  String _typeLabel(AppLocalizations l10n) => switch (invitation.type) {
        InvitationType.gymAdmin => l10n.invitationsTypeGymAdmin,
        InvitationType.staff => l10n.invitationsTypeStaff,
        InvitationType.package => l10n.invitationsTypePackage,
      };

  String? _roleLabel(AppLocalizations l10n) => switch (invitation.role) {
        'GymAdmin' => l10n.staffManagementRoleGymAdmin,
        'BranchManager' => l10n.staffManagementRoleBranchManager,
        'Trainer' => l10n.staffManagementRoleTrainer,
        final String other => other,
        null => null,
      };

  // "Şube · Rol" ya da "Şube · Paket"; GymAdmin firma genelinde çalıştığı
  // için şube yerine "Firma geneli".
  String _detailLine(AppLocalizations l10n) {
    final branch = invitation.role == 'GymAdmin' ? l10n.drawerActiveTaskCompanyWide : invitation.branchName;
    final subject = invitation.type == InvitationType.package ? invitation.packageName : _roleLabel(l10n);
    return [branch, subject].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final detail = _detailLine(l10n);

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
          Text(_typeLabel(l10n), style: textTheme.labelSmall?.copyWith(color: AppColors.onBackgroundMuted)),
          const SizedBox(height: AppSpacing.xs),
          Text(invitation.companyName, style: textTheme.titleMedium),
          if (detail.isNotEmpty) Text(detail, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          if (invitation.invitedByName != null)
            Text(
              l10n.invitationsInvitedBy(invitation.invitedByName!),
              style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint),
            ),
          Text(
            l10n.invitationsExpiresAt(_dateFormat.format(invitation.expiresAt.toLocal())),
            style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundFaint),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onReject,
                  child: Text(l10n.invitationsRejectButton),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy ? null : onAccept,
                  child: isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : Text(l10n.invitationsAcceptButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.onBackgroundFaint),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.invitationsEmptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
