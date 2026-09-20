import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/active_staff_company_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../tenant_onboarding/data/real_tenant_repository.dart';
import '../../../tenant_onboarding/domain/branch_option.dart';
import '../providers/content_library_providers.dart';

class UploadContentItemScreen extends ConsumerStatefulWidget {
  const UploadContentItemScreen({super.key});

  @override
  ConsumerState<UploadContentItemScreen> createState() => _UploadContentItemScreenState();
}

class _UploadContentItemScreenState extends ConsumerState<UploadContentItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _requiredAccessTier = 'Standard';
  int? _selectedBranchId;
  XFile? _pickedFile;
  bool _isSubmitting = false;
  bool _isLoadingBranches = false;
  String? _errorText;
  List<BranchOption>? _branchOptions;

  @override
  void initState() {
    super.initState();
    final activeCompanyId = ref.read(activeStaffCompanyIdProvider);
    final myAssignment = ref.read(currentUserProvider).asData?.value.staffAssignmentFor(activeCompanyId);
    if (myAssignment?.role != 'GymAdmin') {
      _selectedBranchId = myAssignment?.branchId;
    } else {
      _loadBranches();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _pickedFile = file);
  }

  Future<void> _pickVideo() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file != null) setState(() => _pickedFile = file);
  }

  String _mimeTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final pickedFile = _pickedFile;
    if (pickedFile == null) {
      setState(() => _errorText = l10n.contentLibraryUploadFileRequiredMessage);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(contentItemsProvider.notifier).upload(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            requiredAccessTier: _requiredAccessTier,
            branchId: _selectedBranchId,
            filePath: pickedFile.path,
            fileName: pickedFile.name,
            mimeType: _mimeTypeFor(pickedFile.path),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.contentLibraryUploadSuccessMessage)));
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
    final isGymAdmin = myAssignment?.role == 'GymAdmin';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.contentLibraryUploadTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: l10n.contentLibraryUploadTitleLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.commonFieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.contentLibraryUploadDescriptionLabel),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _requiredAccessTier,
                  decoration: InputDecoration(labelText: l10n.contentLibraryUploadTierLabel),
                  items: [
                    DropdownMenuItem(value: 'Standard', child: Text(l10n.contentItemStandardTier)),
                    DropdownMenuItem(value: 'Premium', child: Text(l10n.contentItemPremiumTier)),
                  ],
                  onChanged: (value) => setState(() => _requiredAccessTier = value!),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!isGymAdmin)
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
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.createPackageAllBranchesOption)),
                      ...(_branchOptions ?? const <BranchOption>[])
                          .map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.name))),
                    ],
                    onChanged: (value) => setState(() => _selectedBranchId = value),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(l10n.contentLibraryPickImageButton),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.videocam_outlined),
                        label: Text(l10n.contentLibraryPickVideoButton),
                      ),
                    ),
                  ],
                ),
                if (_pickedFile != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    File(_pickedFile!.path).uri.pathSegments.last,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
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
                      : Text(l10n.contentLibraryUploadSubmitButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
