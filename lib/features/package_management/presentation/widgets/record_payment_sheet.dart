import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/package_providers.dart';

/// Bir personelin, bir paket ataması için nakit/kart/havale ödeme kaydetmesi
/// - backend'de RecordPackageAssignmentPaymentCommand zaten vardı ama
/// personelin hedef atamayı bulabileceği bir liste dahi yoktu (bkz.
/// PackageAssignmentsScreen), o yüzden bu hiç kullanılamıyordu.
Future<void> showRecordPaymentSheet(
  BuildContext context, {
  required int packageAssignmentId,
  required double remainingBalance,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => _RecordPaymentSheet(
      packageAssignmentId: packageAssignmentId,
      remainingBalance: remainingBalance,
    ),
  );
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  const _RecordPaymentSheet({required this.packageAssignmentId, required this.remainingBalance});

  final int packageAssignmentId;
  final double remainingBalance;

  @override
  ConsumerState<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();
  String _method = 'Cash';
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final suggested = widget.remainingBalance > 0 ? widget.remainingBalance : 0;
    _amountController = TextEditingController(text: suggested == 0 ? '' : suggested.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _errorText = l10n.commonFieldRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(packageActionsProvider.notifier).recordPayment(
            packageAssignmentId: widget.packageAssignmentId,
            amount: amount,
            method: _method,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.recordPaymentSuccessMessage)));
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
            Text(l10n.recordPaymentTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.recordPaymentAmountLabel),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: InputDecoration(labelText: l10n.recordPaymentMethodLabel),
              items: [
                DropdownMenuItem(value: 'Cash', child: Text(l10n.recordPaymentMethodCash)),
                DropdownMenuItem(value: 'Card', child: Text(l10n.recordPaymentMethodCard)),
                DropdownMenuItem(value: 'BankTransfer', child: Text(l10n.recordPaymentMethodBankTransfer)),
              ],
              onChanged: (value) => setState(() => _method = value!),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(labelText: l10n.recordPaymentNoteLabel),
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
                  : Text(l10n.recordPaymentSubmitButton),
            ),
          ],
        ),
      ),
    );
  }
}
