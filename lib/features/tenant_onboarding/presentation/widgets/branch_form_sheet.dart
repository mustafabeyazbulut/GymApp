import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/real_tenant_repository.dart';
import '../../domain/branch_summary.dart';

/// Yeni bir şube oluşturmak (companyId verilir, branch null) veya mevcut
/// birini yeniden adlandırmak/adresini değiştirmek (branch verilir) için
/// aynı form - backend'de her ikisi de (POST /api/branches,
/// PATCH /api/branches/{id}) uzun zamandır vardı ama hiçbir mobil giriş
/// noktası yoktu; bir GymAdmin davetini onayladıktan sonra kendi ilk
/// şubesini bile oluşturamıyordu.
Future<void> showBranchFormSheet(
  BuildContext context, {
  required int companyId,
  BranchSummary? branch,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => _BranchFormSheet(companyId: companyId, branch: branch),
  );
}

class _BranchFormSheet extends ConsumerStatefulWidget {
  const _BranchFormSheet({required this.companyId, this.branch});

  final int companyId;
  final BranchSummary? branch;

  @override
  ConsumerState<_BranchFormSheet> createState() => _BranchFormSheetState();
}

class _BranchFormSheetState extends ConsumerState<_BranchFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  bool _isSubmitting = false;
  String? _errorText;

  bool get _isEditing => widget.branch != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch?.name ?? '');
    _addressController = TextEditingController(text: widget.branch?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();
      if (_isEditing) {
        await ref
            .read(tenantRepositoryProvider)
            .updateBranch(branchId: widget.branch!.id, name: name, address: address);
      } else {
        await ref
            .read(tenantRepositoryProvider)
            .createBranch(companyId: widget.companyId, name: name, address: address);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? l10n.branchFormUpdateSuccessMessage : l10n.branchFormCreateSuccessMessage),
      ));
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? l10n.branchFormEditTitle : l10n.branchFormCreateTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.branchFormNameLabel),
                validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.branchFormAddressLabel),
                validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
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
                    : Text(_isEditing ? l10n.branchFormSaveButton : l10n.branchFormCreateButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
