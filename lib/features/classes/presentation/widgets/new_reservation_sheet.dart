import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/class_providers.dart';

/// Bir üyeliğin trainer'ını ve saatini seçip yeni bir Reservation
/// oluşturmak için açılan alt sayfa (bottom sheet). Backend'de bir antrenör
/// müsaitlik takvimi yok - sadece aynı antrenör+saat çakışması 409 ile
/// engelleniyor (bkz. CreateReservationCommandHandler, GymAppApi) - bu
/// yüzden burada da bir müsaitlik göstergesi yok, çakışma submit sırasında
/// sunucudan dönen hatayla öğrenilir.
Future<void> showNewReservationSheet(BuildContext context, {required int packageAssignmentId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => _NewReservationSheet(packageAssignmentId: packageAssignmentId),
  );
}

class _NewReservationSheet extends ConsumerStatefulWidget {
  const _NewReservationSheet({required this.packageAssignmentId});

  final int packageAssignmentId;

  @override
  ConsumerState<_NewReservationSheet> createState() => _NewReservationSheetState();
}

class _NewReservationSheetState extends ConsumerState<_NewReservationSheet> {
  int? _trainerId;
  DateTime? _scheduledAt;
  bool _isSubmitting = false;
  String? _errorText;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null || !mounted) return;

    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_trainerId == null || _scheduledAt == null) {
      setState(() => _errorText = l10n.commonFieldRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(classReservationsProvider.notifier).createReservation(
            trainerId: _trainerId!,
            scheduledAt: _scheduledAt!,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.classesReservationCreatedMessage)),
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trainersAsync = ref.watch(classTrainersProvider(widget.packageAssignmentId));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.classesNewReservationButton, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            trainersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (error, stackTrace) => Text(
                error is ApiException ? error.message : l10n.commonError,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              data: (trainers) {
                if (trainers.isEmpty) {
                  return Text(l10n.classesNoTrainersMessage, style: Theme.of(context).textTheme.bodyMedium);
                }
                return DropdownButtonFormField<int>(
                  initialValue: _trainerId,
                  decoration: InputDecoration(
                    labelText: l10n.classesTrainerLabel,
                    hintText: l10n.classesPickTrainerHint,
                  ),
                  items: trainers
                      .map((trainer) => DropdownMenuItem(value: trainer.id, child: Text(trainer.fullName)))
                      .toList(),
                  onChanged: (value) => setState(() => _trainerId = value),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: _pickDateTime,
              child: Text(
                _scheduledAt == null
                    ? l10n.classesPickDateTimeButton
                    : '${_scheduledAt!.day.toString().padLeft(2, '0')}.'
                        '${_scheduledAt!.month.toString().padLeft(2, '0')}.'
                        '${_scheduledAt!.year} '
                        '${_scheduledAt!.hour.toString().padLeft(2, '0')}:'
                        '${_scheduledAt!.minute.toString().padLeft(2, '0')}',
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_errorText!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : Text(l10n.classesSubmitButton),
            ),
          ],
        ),
      ),
    );
  }
}
