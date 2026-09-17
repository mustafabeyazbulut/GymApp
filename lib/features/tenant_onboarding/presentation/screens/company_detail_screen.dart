import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/real_tenant_repository.dart';
import '../../domain/company_summary.dart';

class CompanyDetailScreen extends ConsumerStatefulWidget {
  const CompanyDetailScreen({required this.companyId, super.key});

  final int companyId;

  @override
  ConsumerState<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  final _nameController = TextEditingController();
  CompanyDetail? _company;
  bool _isLoading = false;
  bool _isSavingName = false;
  bool _isTogglingActive = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final company = await ref.read(tenantRepositoryProvider).getCompanyDetail(widget.companyId);
      if (!mounted) return;
      setState(() {
        _company = company;
        _nameController.text = company.name;
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSavingName = true);
    try {
      await ref.read(tenantRepositoryProvider).updateCompanyName(companyId: widget.companyId, name: name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.companyDetailNameUpdatedMessage)));
      await _load();
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _toggleActive(bool isActive) async {
    setState(() => _isTogglingActive = true);
    try {
      await ref.read(tenantRepositoryProvider).setCompanyActive(companyId: widget.companyId, isActive: isActive);
      if (!mounted) return;
      await _load();
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => _isTogglingActive = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final company = _company;

    return Scaffold(
      appBar: AppBar(title: Text(company?.name ?? l10n.companyManagementTitle)),
      body: SafeArea(
        child: _isLoading && company == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _errorText != null && company == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                      ),
                    ),
                  )
                : company == null
                    ? const SizedBox.shrink()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(labelText: l10n.companyDetailNameLabel),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton(
                              onPressed: _isSavingName ? null : _saveName,
                              child: _isSavingName
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                                    )
                                  : Text(l10n.companyDetailSaveNameButton),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Material(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              child: SwitchListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                                title: Text(l10n.companyDetailActiveLabel),
                                value: company.isActive,
                                onChanged: _isTogglingActive ? null : _toggleActive,
                                activeThumbColor: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(l10n.companyDetailBranchesTitle, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppSpacing.sm),
                            ...company.branches.map(
                              (branch) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Material(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(branch.name, style: Theme.of(context).textTheme.titleSmall),
                                              Text(
                                                branch.address,
                                                style: Theme.of(context).textTheme.bodyMedium
                                                    ?.copyWith(color: AppColors.onBackgroundMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!branch.isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                            decoration: BoxDecoration(
                                              color: AppColors.errorSurface,
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                            ),
                                            child: Text(
                                              l10n.companyManagementInactiveBadge,
                                              style: Theme.of(context).textTheme.labelSmall
                                                  ?.copyWith(color: AppColors.error),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
