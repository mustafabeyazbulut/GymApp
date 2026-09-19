import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/real_progress_repository.dart';

/// Bir antrenörün, birlikte çalıştığı bir üye için teknik/kondisyon
/// puanı + serbest metin not bırakabileceği alt sayfa - Trainer Programım
/// ekranındaki her rezervasyon kartından açılır, o rezervasyonun kendi
/// packageAssignmentId'sini kullanır.
Future<void> showAddProgressNoteSheet(BuildContext context, {required int packageAssignmentId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => _AddProgressNoteSheet(packageAssignmentId: packageAssignmentId),
  );
}

class _AddProgressNoteSheet extends ConsumerStatefulWidget {
  const _AddProgressNoteSheet({required this.packageAssignmentId});

  final int packageAssignmentId;

  @override
  ConsumerState<_AddProgressNoteSheet> createState() => _AddProgressNoteSheetState();
}

class _AddProgressNoteSheetState extends ConsumerState<_AddProgressNoteSheet> {
  double _technique = 50;
  double _condition = 50;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(progressRepositoryProvider).recordProgressNote(
            packageAssignmentId: widget.packageAssignmentId,
            techniqueScore: _technique.round(),
            conditionScore: _condition.round(),
            noteText: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.progressNoteSuccessMessage)));
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
            Text(l10n.progressAddNoteTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            Text('${l10n.progressTechniqueScoreLabel}: ${_technique.round()}',
                style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: _technique,
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: AppColors.primary,
              onChanged: (value) => setState(() => _technique = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('${l10n.progressConditionScoreLabel}: ${_condition.round()}',
                style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: _condition,
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: AppColors.primary,
              onChanged: (value) => setState(() => _condition = value),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(labelText: l10n.progressNoteTextLabel),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_errorText!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : Text(l10n.progressNoteSubmitButton),
            ),
          ],
        ),
      ),
    );
  }
}
