// lib/features/progress/presentation/screens/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/membership_context_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/account_frozen_state.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/circular_stat_gauge.dart';
import '../../../../core/widgets/media_player_screen.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../membership/domain/membership_summary.dart';
import '../../../membership/presentation/widgets/membership_switcher.dart';
import '../../../personal_tracking/presentation/widgets/personal_tracking_section.dart';
import '../../domain/progress_summary.dart';
import '../providers/progress_summary_provider.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeaderBar(title: l10n.progressTitle),
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
        // Kişisel Takibim herkese açık (ana senaryo §5.1); antrenör gelişim
        // notları sadece geçerli paketi olan üyede anlamlı. Paketsiz ya da
        // paketi geçersiz üye boş durum yerine doğrudan kendi takibini görür.
        if (membershipAvailability(memberships).state != MembershipAvailabilityState.valid) {
          return const PersonalTrackingSection();
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelColor: AppColors.onBackground,
                unselectedLabelColor: AppColors.onBackgroundMuted,
                indicatorColor: AppColors.primary,
                dividerColor: AppColors.border,
                tabs: [
                  Tab(text: l10n.progressTrainerSectionTitle),
                  Tab(text: l10n.personalTrackingTitle),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _TrainerSection(memberships: memberships, l10n: l10n),
                    const PersonalTrackingSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Antrenörümden": antrenörün girdiği gelişim notları ve devam özeti.
class _TrainerSection extends ConsumerWidget {
  const _TrainerSection({required this.memberships, required this.l10n});

  final List<MembershipSummary> memberships;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedMembershipIdProvider) ?? memberships.first.id;
    final selected = memberships.firstWhere((m) => m.id == selectedId, orElse: () => memberships.first);

    final summaryAsync = ref.watch(progressSummaryProvider);
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stackTrace) => _ErrorRetry(
        message: error is ApiException ? error.localizedMessage(context) : l10n.commonError,
        onRetry: () => ref.invalidate(progressSummaryProvider),
      ),
      data: (summary) => _ProgressContent(l10n: l10n, memberships: memberships, selectedId: selected.id, summary: summary),
    );
  }
}

class _ProgressContent extends ConsumerWidget {
  const _ProgressContent({
    required this.l10n,
    required this.memberships,
    required this.selectedId,
    required this.summary,
  });

  final AppLocalizations l10n;
  final List<MembershipSummary> memberships;
  final int selectedId;
  final ProgressSummary summary;

  void _openMedia(BuildContext context, ProgressNote note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaPlayerScreen(
          mediaFileId: note.mediaFileId!,
          mediaContentType: note.mediaContentType!,
          title: l10n.progressTrainerNoteLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MembershipSwitcher(
          label: l10n.membershipSwitcherLabel,
          memberships: memberships,
          selectedId: selectedId,
          onSelect: (id) => ref.read(selectedMembershipIdProvider.notifier).select(id),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.progressMonthLabel, style: textTheme.labelSmall),
                Text(l10n.progressClassesCount(summary.classesThisMonth), style: textTheme.titleMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.progressAreasLabel, style: textTheme.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CircularStatGauge(value: summary.techniqueValue, color: AppColors.primary, label: l10n.progressTechnique),
            CircularStatGauge(value: summary.attendanceValue, color: AppColors.secondary, label: l10n.progressAttendance),
            CircularStatGauge(value: summary.conditionValue, color: AppColors.onBackground, label: l10n.progressCondition),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
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
                Text(l10n.progressTrainerNoteLabel, style: textTheme.labelSmall),
                const SizedBox(height: AppSpacing.xs),
                if (summary.latestNote == null)
                  Text(l10n.progressEmptyNotesMessage, style: textTheme.bodyMedium)
                else ...[
                  Text(summary.latestNote!.noteText ?? '', style: textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dateFormat.format(summary.latestNote!.createdAt), style: textTheme.bodyMedium),
                      if (summary.latestNote!.hasMedia)
                        IconButton(
                          icon: Icon(
                            summary.latestNote!.isVideoMedia ? Icons.play_circle_outline : Icons.image_outlined,
                            color: AppColors.primary,
                          ),
                          onPressed: () => _openMedia(context, summary.latestNote!),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (summary.notes.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
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
                  Text(l10n.progressHistoryLabel, style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.sm),
                  for (final note in summary.notes.skip(1))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_dateFormat.format(note.createdAt), style: textTheme.bodyMedium),
                          Expanded(
                            child: Text(
                              note.noteText ?? '',
                              textAlign: TextAlign.end,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                          if (note.hasMedia)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                note.isVideoMedia ? Icons.play_circle_outline : Icons.image_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              onPressed: () => _openMedia(context, note),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
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
