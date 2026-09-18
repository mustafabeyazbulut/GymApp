import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/my_reservation.dart';
import '../providers/my_reservations_provider.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');
final _timeFormat = DateFormat('HH:mm');

enum _ReservationAction { checkIn, noShow, cancel }

/// Bir antrenörün belirli bir üyeyi/PackageAssignment'ı bilmeden
/// GÖREBİLECEĞİ tek ekran - GET /api/reservations/mine üzerinden kendi
/// TrainerId'sine ait tüm rezervasyonları tarih sırasıyla listeler ve her
/// birini check-in/gelmedi/iptal olarak işaretleyebilir (backend'de bu üç
/// mutasyon zaten "reservation.TrainerId == caller" ile kendiliğinden
/// yetkili - burada yeni bir yetki kuralı icat edilmedi, sadece daha önce
/// mobilde hiç erişilemeyen mevcut endpoint'ler kullanıma açıldı).
class TrainerScheduleScreen extends ConsumerWidget {
  const TrainerScheduleScreen({super.key});

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    MyReservation reservation,
    _ReservationAction action,
  ) async {
    if (action == _ReservationAction.cancel || action == _ReservationAction.noShow) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            action == _ReservationAction.cancel
                ? l10n.trainerScheduleCancelConfirmTitle
                : l10n.trainerScheduleNoShowConfirmTitle,
          ),
          content: Text(reservation.memberFullName ?? l10n.trainerScheduleUnknownMemberLabel),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.accountDeletionCancelButton),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.trainerScheduleConfirmButton),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!context.mounted) return;
    final notifier = ref.read(myReservationsProvider.notifier);
    try {
      switch (action) {
        case _ReservationAction.checkIn:
          await notifier.checkIn(reservation.id);
        case _ReservationAction.noShow:
          await notifier.markNoShow(reservation.id);
        case _ReservationAction.cancel:
          await notifier.cancel(reservation.id);
      }
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reservationsAsync = ref.watch(myReservationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerScheduleTitle)),
      body: reservationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is ApiException ? error.message : l10n.commonError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => ref.invalidate(myReservationsProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (reservations) {
          if (reservations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_available_outlined, size: 40, color: AppColors.onBackgroundFaint),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.trainerScheduleEmptyMessage, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: reservations.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _ReservationCard(
              reservation: reservations[index],
              l10n: l10n,
              onAction: (action) => _handleAction(context, ref, l10n, reservations[index], action),
            ),
          );
        },
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation, required this.l10n, required this.onAction});

  final MyReservation reservation;
  final AppLocalizations l10n;
  final ValueChanged<_ReservationAction> onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (statusLabel, isPositive) = switch (reservation.status) {
      MyReservationStatus.booked => (l10n.classesStatusBooked, true),
      MyReservationStatus.checkedIn => (l10n.classesStatusCheckedIn, true),
      MyReservationStatus.cancelled => (l10n.classesStatusCancelled, false),
      MyReservationStatus.noShow => (l10n.classesStatusNoShow, false),
    };
    final isBooked = reservation.status == MyReservationStatus.booked;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateFormat.format(reservation.scheduledAt), style: textTheme.labelSmall),
                Text(_timeFormat.format(reservation.scheduledAt), style: textTheme.titleMedium),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                reservation.memberFullName ?? l10n.trainerScheduleUnknownMemberLabel,
                style: textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusPill(text: statusLabel, isPositive: isPositive),
            if (isBooked)
              PopupMenuButton<_ReservationAction>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.onBackgroundMuted),
                onSelected: onAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _ReservationAction.checkIn,
                    child: Text(l10n.trainerScheduleCheckInAction),
                  ),
                  PopupMenuItem(
                    value: _ReservationAction.noShow,
                    child: Text(l10n.trainerScheduleNoShowAction),
                  ),
                  PopupMenuItem(
                    value: _ReservationAction.cancel,
                    child: Text(l10n.trainerScheduleCancelAction),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
