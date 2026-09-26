import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/staff_permissions_provider.dart';
import '../../../tenant_onboarding/data/real_tenant_repository.dart';
import '../../../tenant_onboarding/domain/branch_option.dart';
import '../providers/package_providers.dart';

class CreatePackageScreen extends ConsumerStatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  ConsumerState<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends ConsumerState<CreatePackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationDaysController = TextEditingController();
  final _sessionCountController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxFreezeDaysController = TextEditingController();
  String _type = 'Duration';
  // Her paket bir şubeye aittir, firma geneli paket yoktur (ana senaryo
  // Karar 5). BranchManager'da aktif görevin şubesine kilitli; GymAdmin
  // şubelerinden birini seçmek zorunda.
  int? _selectedBranchId;
  bool _isSubmitting = false;
  bool _isLoadingBranches = false;
  String? _errorText;
  List<BranchOption>? _branchOptions;

  @override
  void initState() {
    super.initState();
    final fixedBranchId = ref.read(staffPermissionsProvider).fixedBranchId;
    if (fixedBranchId != null) {
      _selectedBranchId = fixedBranchId;
    } else {
      _loadBranches();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationDaysController.dispose();
    _sessionCountController.dispose();
    _priceController.dispose();
    _maxFreezeDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final branches = await ref.read(tenantRepositoryProvider).listBranches();
      if (!mounted) return;
      setState(() => _branchOptions = branches);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final companyId = ref.read(staffPermissionsProvider).activeAssignment?.companyId;
    final branchId = _selectedBranchId;
    if (companyId == null || branchId == null) {
      setState(() => _errorText = l10n.commonError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(packageActionsProvider.notifier).createPackage(
            companyId: companyId,
            branchId: branchId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            type: _type,
            durationDays: _type == 'Duration' ? int.tryParse(_durationDaysController.text.trim()) : null,
            sessionCount: _type == 'SessionBased' ? int.tryParse(_sessionCountController.text.trim()) : null,
            price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
            maxFreezeDays: int.tryParse(_maxFreezeDaysController.text.trim()),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.createPackageSuccessMessage)));
      Navigator.of(context).pop();
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
    final permissions = ref.watch(staffPermissionsProvider);
    final fixedBranchId = permissions.fixedBranchId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createPackageTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.createPackageNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.createPackageDescriptionLabel),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: InputDecoration(labelText: l10n.createPackageTypeLabel),
                  items: [
                    DropdownMenuItem(value: 'Duration', child: Text(l10n.packageTypeDuration)),
                    DropdownMenuItem(value: 'SessionBased', child: Text(l10n.packageTypeSessionBased)),
                  ],
                  onChanged: (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_type == 'Duration')
                  TextFormField(
                    controller: _durationDaysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.createPackageDurationDaysLabel),
                    validator: (value) =>
                        (value == null || int.tryParse(value.trim()) == null) ? l10n.commonFieldRequired : null,
                  )
                else
                  TextFormField(
                    controller: _sessionCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.createPackageSessionCountLabel),
                    validator: (value) {
                      final parsed = value == null ? null : int.tryParse(value.trim());
                      return (parsed == null || parsed <= 0) ? l10n.commonFieldRequired : null;
                    },
                  ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.createPackagePriceLabel),
                  validator: (value) {
                    final parsed = value == null ? null : double.tryParse(value.trim().replaceAll(',', '.'));
                    return (parsed == null || parsed < 0) ? l10n.commonFieldRequired : null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _maxFreezeDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.createPackageMaxFreezeDaysLabel,
                    hintText: l10n.createPackageMaxFreezeDaysHint,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed = int.tryParse(value.trim());
                    return (parsed == null || parsed <= 0) ? l10n.commonFieldRequired : null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                if (fixedBranchId != null)
                  TextFormField(
                    enabled: false,
                    initialValue: permissions.activeAssignment?.branchName ?? l10n.addStaffMemberBranchLabel,
                    decoration: InputDecoration(labelText: l10n.addStaffMemberBranchLabel),
                  )
                else if (_isLoadingBranches)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else
                  // Varsayılan seçim yok: GymAdmin paketin hangi şubeye ait
                  // olduğunu bilinçli olarak seçmeli.
                  DropdownButtonFormField<int>(
                    initialValue: _selectedBranchId,
                    decoration: InputDecoration(labelText: l10n.addStaffMemberBranchLabel),
                    items: (_branchOptions ?? const <BranchOption>[])
                        .map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.name)))
                        .toList(),
                    validator: (value) => value == null ? l10n.createPackageBranchRequired : null,
                    onChanged: (value) => setState(() => _selectedBranchId = value),
                  ),
                if (_errorText != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_errorText!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error)),
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
                      : Text(l10n.createPackageSubmitButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
