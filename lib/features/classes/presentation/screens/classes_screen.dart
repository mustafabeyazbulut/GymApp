import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/membership_context_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/account_frozen_state.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/package_status_empty_state.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../class_scheduling/domain/class_enrollment.dart';
import '../../../class_scheduling/domain/class_session.dart';
import '../../../class_scheduling/presentation/providers/class_scheduling_providers.dart';
import '../../../membership/domain/membership_summary.dart';
import '../../../membership/presentation/widgets/membership_switcher.dart';
import '../../domain/reservation.dart';
import '../../domain/trainer.dart';
import '../providers/class_providers.dart';
import '../widgets/new_reservation_sheet.dart';

final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
final _dateFormat = DateFormat('dd.MM.yyyy');

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
        final selectedId = ref.watch(selectedMembershipIdProvider) ?? memberships.firstOrNull?.id;
        // Backend geçerli paketi olmayan üyeye ders listesini boş döndüğü için
        // "ders yok" yerine asıl neden gösterilir (paketi yok / geçersiz).
        final availability = membershipAvailability(memberships, selectedId: selectedId);
        if (availability.state != MembershipAvailabilityState.valid) {
          return PackageStatusEmptyState(availability: availability);
        }

        final selected = memberships.firstWhere((m) => m.id == selectedId, orElse: () => memberships.first);
        // PT randevusu seans hakkı gerektirir (süre bazlı pakette randevu yok).
        final isEligibleForBooking = selected.isValid && (selected.remainingSessions ?? 0) > 0;

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
            const SizedBox(height: AppSpacing.xl),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.groupClassSectionTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _GroupClassSchedule(memberships: memberships, l10n: l10n),
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

// Kapasiteli grup dersi haftalık programı - ayrı bir modül (ClassSession/
// ClassEnrollment), yukarıdaki PT randevu (Reservation) akışından bağımsız.
// Her ders için doluluk göstergesi ve Katıl/İptal Et butonu; uygun paketi
// yoksa (kategori eşleşen aktif bir üyelik) buton devre dışı + sebep metni.
class _GroupClassSchedule extends ConsumerWidget {
  const _GroupClassSchedule({required this.memberships, required this.l10n});

  final List<MembershipSummary> memberships;
  final AppLocalizations l10n;

  static MembershipSummary? _eligibleMembershipFor(
      List<MembershipSummary> memberships, ClassSessionCategory category) {
    final apiCategory = classSessionCategoryToApi(category);
    for (final membership in memberships) {
      if (membership.category == apiCategory && membership.isValid) return membership;
    }
    return null;
  }

  Future<void> _enroll(BuildContext context, WidgetRef ref, ClassSession session, int packageAssignmentId) async {
    try {
      await ref
          .read(weeklyClassSessionsProvider.notifier)
          .enroll(classSessionId: session.id, packageAssignmentId: packageAssignmentId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupClassEnrolledMessage)));
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  Future<void> _cancelEnrollment(BuildContext context, WidgetRef ref, int classEnrollmentId) async {
    try {
      await ref.read(myClassEnrollmentsProvider.notifier).cancel(classEnrollmentId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.groupClassCancelledMessage)));
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(weeklyClassSessionsProvider);
    final enrollmentsAsync = ref.watch(myClassEnrollmentsProvider);

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stackTrace) => Text(
        error is ApiException ? error.localizedMessage(context) : l10n.commonError,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(l10n.groupClassEmptyMessage, style: Theme.of(context).textTheme.bodyMedium),
            ),
          );
        }

        final enrollments = enrollmentsAsync.asData?.value ?? const <MyClassEnrollment>[];
        final reservedBySessionId = {
          for (final enrollment in enrollments)
            if (enrollment.status == ClassEnrollmentStatus.reserved) enrollment.classSessionId: enrollment,
        };

        final sorted = [...sessions]
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return byDate != 0 ? byDate : a.startTime.compareTo(b.startTime);
          });

        return Column(
          children: [
            for (final session in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ClassSessionCard(
                  session: session,
                  l10n: l10n,
                  existingEnrollment: reservedBySessionId[session.id],
                  eligibleMembership: _eligibleMembershipFor(memberships, session.category),
                  onEnroll: (membershipId) => _enroll(context, ref, session, membershipId),
                  onCancel: (enrollmentId) => _cancelEnrollment(context, ref, enrollmentId),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ClassSessionCard extends StatelessWidget {
  const _ClassSessionCard({
    required this.session,
    required this.l10n,
    required this.existingEnrollment,
    required this.eligibleMembership,
    required this.onEnroll,
    required this.onCancel,
  });

  final ClassSession session;
  final AppLocalizations l10n;
  final MyClassEnrollment? existingEnrollment;
  final MembershipSummary? eligibleMembership;
  final ValueChanged<int> onEnroll;
  final ValueChanged<int> onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryLabel = session.category == ClassSessionCategory.groupClass
        ? l10n.classSessionCategoryGroupClass
        : l10n.classSessionCategoryMartialArts;
    final isEnrolled = existingEnrollment != null;
    final isFull = session.isFull;

    String? disabledReason;
    if (!isEnrolled) {
      if (isFull) {
        disabledReason = l10n.groupClassFullMessage;
      } else if (eligibleMembership == null) {
        disabledReason = l10n.groupClassNotEligibleMessage;
      }
    }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.name, style: textTheme.titleMedium),
                      Text(
                        '${_dateFormat.format(session.date)}  ${session.startTimeLabel}-${session.endTimeLabel}',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  text: l10n.groupClassOccupancyLabel(session.enrolledCount, session.capacity),
                  isPositive: !isFull,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(categoryLabel, style: textTheme.bodySmall?.copyWith(color: AppColors.onBackgroundMuted)),
            const SizedBox(height: AppSpacing.md),
            if (isEnrolled)
              OutlinedButton(
                onPressed: () => onCancel(existingEnrollment!.id),
                child: Text(l10n.groupClassCancelButton),
              )
            else ...[
              ElevatedButton(
                onPressed: disabledReason == null ? () => onEnroll(eligibleMembership!.id) : null,
                child: Text(l10n.groupClassEnrollButton),
              ),
              if (disabledReason != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  disabledReason,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.onBackgroundFaint),
                ),
              ],
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
