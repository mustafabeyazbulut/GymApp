import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/real_tenant_repository.dart';
import '../../domain/branch_option.dart';

class AddStaffMemberScreen extends ConsumerStatefulWidget {
  const AddStaffMemberScreen({super.key});

  @override
  ConsumerState<AddStaffMemberScreen> createState() => _AddStaffMemberScreenState();
}

class _AddStaffMemberScreenState extends ConsumerState<AddStaffMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _phone;
  String _role = 'Member';
  int? _selectedBranchId;
  bool _isSubmitting = false;
  String? _errorText;
  List<BranchOption>? _branchOptions;
  bool _isLoadingBranches = false;

  @override
  void initState() {
    super.initState();
    // A Branch Manager's own branch is fixed; a Gym Admin (branchId == null
    // on their own assignment) picks from their company's branches.
    final myAssignment = ref.read(currentUserProvider).asData?.value.staffAssignment;
    if (myAssignment?.branchId != null) {
      _selectedBranchId = myAssignment!.branchId;
    } else {
      _loadBranches();
    }
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final branches = await ref.read(tenantRepositoryProvider).listBranches();
      if (!mounted) return;
      setState(() {
        _branchOptions = branches;
        _selectedBranchId = branches.isNotEmpty ? branches.first.id : null;
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.message);
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_phone == null || _phone!.trim().isEmpty || _selectedBranchId == null) {
      setState(() => _errorText = l10n.commonFieldRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(tenantRepositoryProvider).addStaffMember(
            fullName: _nameController.text.trim(),
            phone: _phone!,
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            role: _role,
            branchId: _selectedBranchId!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addStaffMemberSuccessMessage)));
      Navigator.of(context).pop();
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
    final myAssignment = ref.watch(currentUserProvider).asData?.value.staffAssignment;
    final fixedBranchId = myAssignment?.branchId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addStaffMemberTitle)),
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
                  decoration: InputDecoration(labelText: l10n.addStaffMemberNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                IntlPhoneField(
                  initialCountryCode: 'TR',
                  decoration: InputDecoration(labelText: l10n.addStaffMemberPhoneLabel),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (phone) => _phone = phone.completeNumber,
                  validator: (phone) => (phone == null || phone.number.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.addStaffMemberEmailLabel),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: InputDecoration(labelText: l10n.addStaffMemberRoleLabel),
                  items: [
                    DropdownMenuItem(value: 'Member', child: Text(l10n.addStaffMemberRoleMember)),
                    DropdownMenuItem(value: 'Trainer', child: Text(l10n.addStaffMemberRoleTrainer)),
                  ],
                  onChanged: (value) => setState(() => _role = value!),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (fixedBranchId != null)
                  TextFormField(
                    enabled: false,
                    initialValue: myAssignment?.companyName ?? l10n.addStaffMemberBranchLabel,
                    decoration: InputDecoration(labelText: l10n.addStaffMemberBranchLabel),
                  )
                else if (_isLoadingBranches)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedBranchId,
                    decoration: InputDecoration(labelText: l10n.addStaffMemberBranchLabel),
                    items: (_branchOptions ?? const <BranchOption>[])
                        .map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.name)))
                        .toList(),
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
                      : Text(l10n.addStaffMemberSubmitButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
