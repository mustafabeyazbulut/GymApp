import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/branch_list_provider.dart';

class BranchFormScreen extends ConsumerStatefulWidget {
  const BranchFormScreen({super.key});

  @override
  ConsumerState<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends ConsumerState<BranchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _companyIdController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(branchListProvider.notifier).addBranch(
            companyId: int.parse(_companyIdController.text),
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
          );
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            e.message,
            style: const TextStyle(color: AppColors.onPrimary),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.branchFormTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _companyIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.branchFormCompanyIdLabel),
                validator: (value) {
                  final parsed = value == null ? null : int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return l10n.branchFormValidationCompanyId;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.branchFormNameLabel),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? l10n.branchFormValidationRequired : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: l10n.branchFormAddressLabel),
                maxLines: 2,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? l10n.branchFormValidationRequired : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(l10n.branchFormSubmitButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
