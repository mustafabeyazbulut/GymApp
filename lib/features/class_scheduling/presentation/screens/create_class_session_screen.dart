import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/active_staff_company_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../tenant_onboarding/data/real_tenant_repository.dart';
import '../../../tenant_onboarding/domain/branch_option.dart';
import '../../../tenant_onboarding/domain/staff_member_summary.dart';
import '../../domain/class_session.dart';
import '../providers/class_scheduling_providers.dart';

// Staff (GymAdmin/BranchManager) için "Ders Programı Oluştur" formu -
// CreatePackageScreen'in sabit/seçilebilir şube deseniyle aynı: bir
// BranchManager'ın zaten tek bir şubesi vardır, bir GymAdmin şubelerinden
// birini seçer.
class CreateClassSessionScreen extends ConsumerStatefulWidget {
  const CreateClassSessionScreen({super.key});

  @override
  ConsumerState<CreateClassSessionScreen> createState() => _CreateClassSessionScreenState();
}

class _CreateClassSessionScreenState extends ConsumerState<CreateClassSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _cutoffHoursController = TextEditingController(text: '2');

  ClassSessionCategory _category = ClassSessionCategory.groupClass;
  int? _selectedBranchId;
  int? _selectedTrainerUserId;
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isSubmitting = false;
  bool _isLoadingBranches = false;
  bool _isLoadingStaff = false;
  String? _errorText;
  List<BranchOption>? _branchOptions;
  List<StaffMemberSummary>? _staffMembers;

  @override
  void initState() {
    super.initState();
    final activeCompanyId = ref.read(activeStaffCompanyIdProvider);
    final myAssignment = ref.read(currentUserProvider).asData?.value.staffAssignmentFor(activeCompanyId);
    if (myAssignment?.branchId != null) {
      _selectedBranchId = myAssignment!.branchId;
    } else {
      _loadBranches();
    }
    _loadStaff();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _cutoffHoursController.dispose();
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

  Future<void> _loadStaff() async {
    setState(() => _isLoadingStaff = true);
    try {
      final staff = await ref.read(tenantRepositoryProvider).getStaffMembers();
      if (!mounted) return;
      setState(() => _staffMembers = staff);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay.now());
    if (picked == null || !mounted) return;
    setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay.now());
    if (picked == null || !mounted) return;
    setState(() => _endTime = picked);
  }

  String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranchId == null ||
        _selectedTrainerUserId == null ||
        _date == null ||
        _startTime == null ||
        _endTime == null) {
      setState(() => _errorText = l10n.commonFieldRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(classSessionActionsProvider.notifier).createClassSession(
            branchId: _selectedBranchId!,
            trainerUserId: _selectedTrainerUserId!,
            category: _category,
            name: _nameController.text.trim(),
            date: _date!,
            startTime: _formatTimeOfDay(_startTime!),
            endTime: _formatTimeOfDay(_endTime!),
            capacity: int.parse(_capacityController.text.trim()),
            cancellationCutoffHours: int.parse(_cutoffHoursController.text.trim()),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.createClassSessionSuccessMessage)));
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

    final trainersForBranch = (_staffMembers ?? const <StaffMemberSummary>[])
        .where((member) => member.role == 'Trainer' && member.branchId == _selectedBranchId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createClassSessionTitle)),
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
                  decoration: InputDecoration(labelText: l10n.createClassSessionNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<ClassSessionCategory>(
                  initialValue: _category,
                  decoration: InputDecoration(labelText: l10n.createClassSessionCategoryLabel),
                  items: [
                    DropdownMenuItem(
                      value: ClassSessionCategory.groupClass,
                      child: Text(l10n.classSessionCategoryGroupClass),
                    ),
                    DropdownMenuItem(
                      value: ClassSessionCategory.martialArts,
                      child: Text(l10n.classSessionCategoryMartialArts),
                    ),
                  ],
                  onChanged: (value) => setState(() => _category = value!),
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
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedBranchId,
                    decoration: InputDecoration(labelText: l10n.addStaffMemberBranchLabel),
                    items: (_branchOptions ?? const <BranchOption>[])
                        .map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.name)))
                        .toList(),
                    onChanged: (value) => setState(() {
                      _selectedBranchId = value;
                      _selectedTrainerUserId = null;
                    }),
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (_isLoadingStaff)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else if (trainersForBranch.isEmpty)
                  Text(l10n.createClassSessionNoTrainersMessage, style: Theme.of(context).textTheme.bodyMedium)
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedTrainerUserId,
                    decoration: InputDecoration(labelText: l10n.createClassSessionTrainerLabel),
                    items: trainersForBranch
                        .map((trainer) => DropdownMenuItem(value: trainer.userId, child: Text(trainer.fullName)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedTrainerUserId = value),
                  ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: _pickDate,
                  child: Text(
                    _date == null
                        ? l10n.createClassSessionPickDateButton
                        : '${_date!.day.toString().padLeft(2, '0')}.${_date!.month.toString().padLeft(2, '0')}.${_date!.year}',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickStartTime,
                        child: Text(
                          _startTime == null
                              ? l10n.createClassSessionPickStartTimeButton
                              : _formatTimeOfDay(_startTime!),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickEndTime,
                        child: Text(
                          _endTime == null ? l10n.createClassSessionPickEndTimeButton : _formatTimeOfDay(_endTime!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.createClassSessionCapacityLabel),
                  validator: (value) {
                    final parsed = value == null ? null : int.tryParse(value.trim());
                    return (parsed == null || parsed <= 0) ? l10n.commonFieldRequired : null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _cutoffHoursController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.createClassSessionCutoffHoursLabel),
                  validator: (value) {
                    final parsed = value == null ? null : int.tryParse(value.trim());
                    return (parsed == null || parsed < 0) ? l10n.commonFieldRequired : null;
                  },
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
                      : Text(l10n.createClassSessionSubmitButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
