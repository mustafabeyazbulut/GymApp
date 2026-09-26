import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/format/localized_decimal.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/personal_log.dart';
import '../providers/personal_log_providers.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');

/// Kişisel takip kaydı ekleme/düzenleme alt sayfası. [existing] verilirse
/// düzenleme modunda açılır. Antrenmanda başlık, ölçümde en az bir ölçü
/// zorunlu; ondalıklar dile göre (tr: virgül) yazılır.
Future<void> showPersonalLogSheet(BuildContext context, {PersonalLog? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => _PersonalLogSheet(existing: existing),
  );
}

class _PersonalLogSheet extends ConsumerStatefulWidget {
  const _PersonalLogSheet({required this.existing});

  final PersonalLog? existing;

  @override
  ConsumerState<_PersonalLogSheet> createState() => _PersonalLogSheetState();
}

class _PersonalLogSheetState extends ConsumerState<_PersonalLogSheet> {
  final _formKey = GlobalKey<FormState>();
  late PersonalLogKind _kind;
  late DateTime _date;
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _waistController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;
  bool _didFillFromExisting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now();
    _kind = existing?.kind ?? PersonalLogKind.workout;
    _date = existing?.date ?? DateTime(now.year, now.month, now.day);
    _titleController.text = existing?.title ?? '';
    _durationController.text = existing?.durationMinutes?.toString() ?? '';
    _notesController.text = existing?.notes ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ölçüler dile göre biçimlenir - Locale ancak burada okunabilir.
    if (_didFillFromExisting) return;
    _didFillFromExisting = true;
    final existing = widget.existing;
    if (existing == null) return;
    final locale = Localizations.localeOf(context);
    String format(double? value) => value == null ? '' : formatLocalizedDecimal(value, locale, maxFractionDigits: 2);
    _weightController.text = format(existing.weightKg);
    _bodyFatController.text = format(existing.bodyFatPercent);
    _waistController.text = format(existing.waistCm);
  }

  @override
  void dispose() {
    for (final controller in [
      _titleController,
      _durationController,
      _notesController,
      _weightController,
      _bodyFatController,
      _waistController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  double? _decimal(TextEditingController controller) =>
      parseLocalizedDecimal(controller.text, Localizations.localeOf(context));

  // Boş bırakılabilir; doluysa pozitif, dile uygun bir sayı olmalı.
  String? _validateDecimal(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = parseLocalizedDecimal(value, Localizations.localeOf(context));
    return (parsed == null || parsed <= 0) ? l10n.personalLogInvalidNumber : null;
  }

  String? _optionalText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _errorText = null);
    if (!_formKey.currentState!.validate()) return;

    final isWorkout = _kind == PersonalLogKind.workout;
    final draft = PersonalLogDraft(
      date: _date,
      kind: _kind,
      title: isWorkout ? _optionalText(_titleController) : null,
      durationMinutes: isWorkout ? int.tryParse(_durationController.text.trim()) : null,
      notes: _optionalText(_notesController),
      weightKg: isWorkout ? null : _decimal(_weightController),
      bodyFatPercent: isWorkout ? null : _decimal(_bodyFatController),
      waistCm: isWorkout ? null : _decimal(_waistController),
    );
    if (!isWorkout && draft.weightKg == null && draft.bodyFatPercent == null && draft.waistCm == null) {
      setState(() => _errorText = l10n.personalLogMeasurementRequired);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(personalLogActionsProvider.notifier).save(draft, id: widget.existing?.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.personalLogSavedMessage)));
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final isWorkout = _kind == PersonalLogKind.workout;
    const decimalKeyboard = TextInputType.numberWithOptions(decimal: true);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? l10n.personalLogAddTitle : l10n.personalLogEditTitle,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              SegmentedButton<PersonalLogKind>(
                segments: [
                  ButtonSegment(value: PersonalLogKind.workout, label: Text(l10n.personalLogKindWorkout)),
                  ButtonSegment(value: PersonalLogKind.measurement, label: Text(l10n.personalLogKindMeasurement)),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) => setState(() {
                  _kind = selection.first;
                  _errorText = null;
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l10n.personalLogDateLabel),
                  child: Text(_dateFormat.format(_date)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isWorkout) ...[
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: l10n.personalLogTitleLabel),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? l10n.personalLogTitleRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.personalLogDurationLabel),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed = int.tryParse(value.trim());
                    return (parsed == null || parsed <= 0) ? l10n.personalLogInvalidNumber : null;
                  },
                ),
              ] else ...[
                TextFormField(
                  controller: _weightController,
                  keyboardType: decimalKeyboard,
                  decoration: InputDecoration(labelText: l10n.personalLogWeightLabel),
                  validator: (value) => _validateDecimal(value, l10n),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _bodyFatController,
                  keyboardType: decimalKeyboard,
                  decoration: InputDecoration(labelText: l10n.personalLogBodyFatLabel),
                  validator: (value) => _validateDecimal(value, l10n),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _waistController,
                  keyboardType: decimalKeyboard,
                  decoration: InputDecoration(labelText: l10n.personalLogWaistLabel),
                  validator: (value) => _validateDecimal(value, l10n),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.personalLogNotesLabel),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_errorText!, style: textTheme.labelSmall?.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : Text(l10n.personalLogSaveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
