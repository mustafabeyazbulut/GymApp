import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/account_frozen_state.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/empty_membership_state.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_exceptions.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../domain/class_session.dart';
import '../providers/class_list_provider.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  ClassCategory? _selectedCategory;
  int _reservingId = -1;
  int _selectedDayIndex = 1;

  static const _weekDates = [
    ('22', 'Pzt'), ('23', 'Sal'), ('24', 'Çar'), ('25', 'Per'), ('26', 'Cum'),
  ];

  Future<void> _reserve(int classId) async {
    setState(() => _reservingId = classId);
    try {
      await ref.read(classListProvider.notifier).reserveSpot(classId);
    } catch (_) {
      // Gerçekçi olarak yalnızca bu butonun disabled durumu bir kare
      // render etmeden önce yapılan hızlı bir çift dokunuşla tetiklenebilir
      // (repository, zaten dolu/zaten rezerve edilmiş bir seans için
      // StateError fırlatır) — yine de sessizce başarısız olmak yerine
      // kullanıcıya gösterilmesi gerekir.
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonError)),
      );
    } finally {
      if (mounted) setState(() => _reservingId = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeaderBar(title: l10n.classesTitle),
      body: ref.watch(currentUserProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is AuthException ? error.message : l10n.commonError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (currentUser) {
          if (currentUser.isAccountFrozen) {
            return const AccountFrozenState();
          }
          if (!currentUser.hasActiveMembership) {
            return const EmptyMembershipState();
          }
          final sessionsAsync = ref.watch(classListProvider);
          return sessionsAsync.when(
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
                      onPressed: () => ref.invalidate(classListProvider),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
            data: (sessions) {
              final filtered = _selectedCategory == null
                  ? sessions
                  : sessions.where((s) => s.category == _selectedCategory).toList();

              return Column(
                children: [
                  // Dekoratif tarih şeridi — spesifikasyona göre farklı bir gün seçmek
                  // aşağıda gösterilen seansları değiştirmez (eksik bir özellik değil,
                  // bilinçli bir sadeleştirme).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: Row(
                      children: [
                        for (var i = 0; i < _weekDates.length; i++)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedDayIndex = i),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: i == _selectedDayIndex ? AppColors.primary : Colors.transparent,
                                  border: i == _selectedDayIndex ? null : Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _weekDates[i].$1,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: i == _selectedDayIndex
                                                ? AppColors.onPrimary
                                                : AppColors.onBackground,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      _weekDates[i].$2,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: i == _selectedDayIndex
                                                ? AppColors.onPrimary.withValues(alpha: 0.7)
                                                : AppColors.onBackgroundFaint,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(l10n.classesFilterAll),
                          selected: _selectedCategory == null,
                          onSelected: (_) => setState(() => _selectedCategory = null),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ChoiceChip(
                          label: Text(l10n.classesCategoryBjj),
                          selected: _selectedCategory == ClassCategory.bjj,
                          onSelected: (_) => setState(() => _selectedCategory = ClassCategory.bjj),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ChoiceChip(
                          label: Text(l10n.classesCategoryFitness),
                          selected: _selectedCategory == ClassCategory.fitness,
                          onSelected: (_) => setState(() => _selectedCategory = ClassCategory.fitness),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.event_busy_outlined,
                                    size: 40,
                                    color: AppColors.onBackgroundFaint,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    l10n.classesEmptyFilterMessage,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) => _ClassCard(
                              session: filtered[index],
                              isReserving: _reservingId == filtered[index].id,
                              onReserve: () => _reserve(filtered[index].id),
                              l10n: l10n,
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.session,
    required this.isReserving,
    required this.onReserve,
    required this.l10n,
  });

  final ClassSession session;
  final bool isReserving;
  final VoidCallback onReserve;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryLabel =
        session.category == ClassCategory.bjj ? l10n.classesCategoryBjj : l10n.classesCategoryFitness;

    return Container(
      decoration: BoxDecoration(
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
                Text(session.name, style: textTheme.titleMedium),
                StatusPill(text: categoryLabel, isPositive: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${session.timeRange} · ${session.trainerName} · '
              '${l10n.classesCapacityLabel(session.enrolledCount, session.capacity)}',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (session.isReservedByMe)
              ElevatedButton(onPressed: null, child: Text(l10n.classesReservedButton))
            else if (session.isFull)
              OutlinedButton(onPressed: null, child: Text(l10n.classesWaitlistButton))
            else
              ElevatedButton(
                onPressed: isReserving ? null : onReserve,
                child: isReserving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : Text(l10n.classesReserveButton),
              ),
          ],
        ),
      ),
    );
  }
}
