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
import '../../../membership/domain/membership_summary.dart';
import '../../../membership/presentation/widgets/membership_switcher.dart';
import '../../domain/reservation.dart';
import '../../domain/trainer.dart';
import '../providers/class_providers.dart';
import '../widgets/new_reservation_sheet.dart';

final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  Future<void> _cancel(BuildContext context, WidgetRef ref, int reservationId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(classReservationsProvider.notifier).cancelReservation(reservationId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.classesReservationCancelledMessage)),
      );
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeaderBar(title: l10n.classesTitle),
      body: _buildBody(context, ref, l10n),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentUserAsync = ref.watch(currentUserProvider);
    if (currentUserAsync.hasError) {
      final error = currentUserAsync.error;
      return _ErrorRetry(
        message: error is AuthException ? error.localizedMessage(context) : l10n.commonError,
        onRetry: () => ref.invalidate(currentUserProvider),
      );
    }
    if (currentUserAsync.value?.isAccountFrozen ?? false) {
      return const AccountFrozenState();
    }

    final membershipsAsync = ref.watch(membershipsProvider);
    return membershipsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stackTrace) => _ErrorRetry(
        message: error is ApiException ? error.localizedMessage(context) : l10n.commonError,
        onRetry: () => ref.invalidate(membershipsProvider),
      ),
      data: (memberships) {
        if (memberships.isEmpty) {
          return const EmptyMembershipState();
        }

        final selectedId = ref.watch(selectedMembershipIdProvider) ?? memberships.first.id;
        final selected = memberships.firstWhere((m) => m.id == selectedId, orElse: () => memberships.first);
        final isEligibleForBooking =
            selected.status == MembershipStatus.active && (selected.remainingSessions ?? 0) > 0;

        final trainersAsync = ref.watch(classTrainersProvider(selected.id));
        final reservationsAsync = ref.watch(classReservationsProvider);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            MembershipSwitcher(
              label: l10n.membershipSwitcherLabel,
              memberships: memberships,
              selectedId: selected.id,
              onSelect: (id) => ref.read(selectedMembershipIdProvider.notifier).select(id),
            ),
            ElevatedButton(
              onPressed: isEligibleForBooking
                  ? () => showNewReservationSheet(context, packageAssignmentId: selected.id)
                  : null,
              child: Text(l10n.classesNewReservationButton),
            ),
            if (!isEligibleForBooking) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.classesNotEligibleMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            reservationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (error, stackTrace) => Text(
                error is ApiException ? error.localizedMessage(context) : l10n.commonError,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              data: (reservations) {
                if (reservations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Column(
                        children: [
                          const Icon(Icons.event_busy_outlined, size: 40, color: AppColors.onBackgroundFaint),
                          const SizedBox(height: AppSpacing.md),
                          Text(l10n.classesEmptyMessage, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  );
                }

                final trainers = trainersAsync.asData?.value ?? const <Trainer>[];
                final trainerNames = {for (final trainer in trainers) trainer.id: trainer.fullName};

                final sorted = [...reservations]..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
                return Column(
                  children: [
                    for (final reservation in sorted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ReservationCard(
                          reservation: reservation,
                          trainerName: trainerNames[reservation.trainerId] ??
                              l10n.classesTrainerFallbackLabel(reservation.trainerId),
                          l10n: l10n,
                          onCancel: () => _cancel(context, ref, reservation.id),
                        ),
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

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.trainerName,
    required this.l10n,
    required this.onCancel,
  });

  final Reservation reservation;
  final String trainerName;
  final AppLocalizations l10n;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (statusLabel, isPositive) = switch (reservation.status) {
      ReservationStatus.booked => (l10n.classesStatusBooked, true),
      ReservationStatus.checkedIn => (l10n.classesStatusCheckedIn, true),
      ReservationStatus.cancelled => (l10n.classesStatusCancelled, false),
      ReservationStatus.noShow => (l10n.classesStatusNoShow, false),
    };

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
                Text(_dateTimeFormat.format(reservation.scheduledAt), style: textTheme.titleMedium),
                StatusPill(text: statusLabel, isPositive: isPositive),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(trainerName, style: textTheme.bodyMedium),
            if (reservation.status == ReservationStatus.booked) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: onCancel, child: Text(l10n.classesCancelReservationButton)),
            ],
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
