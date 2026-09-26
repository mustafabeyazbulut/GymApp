import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/active_staff_company_provider.dart';
import '../../../../core/widgets/phone_number_field.dart';
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
  String? _phone;
  // Gym üyeliği paketle oluşur (ana senaryo §3.2) - bu ekran sadece personel
  // yetkisi verir, bu yüzden 'Member' rolü yok.
  String _role = 'Trainer';
  int? _selectedBranchId;
  bool _isSubmitting = false;
  String? _errorText;
  List<BranchOption>? _branchOptions;
  bool _isLoadingBranches = false;

  @override
  void initState() {
    super.initState();
    // Bir Branch Manager'ın kendi şubesi sabittir; bir Gym Admin (kendi
    // assignment'ında branchId == null) kendi şirketinin şubeleri arasından
    // seçim yapar. staffAssignmentFor, çok şirketli bir GymAdmin'in
    // drawer'dan seçtiği "Aktif Şirket"i yansıtır (bkz.
    // active_staff_company_provider.dart) - aynı seçim dioProvider
    // tarafından X-Active-Company-Id header'ı olarak zaten gönderiliyor, bu
    // yüzden listBranches()'ın döndürdüğü şubeler de bu şirkete ait olacak.
    final activeCompanyId = ref.read(activeStaffCompanyIdProvider);
    final myAssignment = ref.read(currentUserProvider).asData?.value.staffAssignmentFor(activeCompanyId);
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
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
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
            phone: _phone!,
            role: _role,
            branchId: _selectedBranchId!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addStaffMemberSuccessMessage)));
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
    final activeCompanyId = ref.watch(activeStaffCompanyIdProvider);
    final myAssignment = ref.watch(currentUserProvider).asData?.value.staffAssignmentFor(activeCompanyId);
    final fixedBranchId = myAssignment?.branchId;
    // Şube Müdürü atamak sadece aktif firmada GymAdmin olana açık.
    final canAssignBranchManager = myAssignment?.role == 'GymAdmin';

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
                PhoneNumberField(
                  labelText: l10n.addStaffMemberPhoneLabel,
                  onChanged: (phone) => _phone = phone,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    l10n.addStaffMemberPhoneHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: InputDecoration(labelText: l10n.addStaffMemberRoleLabel),
                  items: [
                    DropdownMenuItem(value: 'Trainer', child: Text(l10n.addStaffMemberRoleTrainer)),
                    if (canAssignBranchManager)
                      DropdownMenuItem(value: 'BranchManager', child: Text(l10n.addStaffMemberRoleBranchManager)),
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
