import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_pill.dart';
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
      body: SafeArea(child: _buildBody(context, l10n, company)),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, CompanyDetail? company) {
    if (_isLoading && company == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_errorText != null && company == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorText!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: _load, child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      );
    }
    if (company == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
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
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  company.isActive ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
                  color: company.isActive ? AppColors.primary : AppColors.onBackgroundFaint,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(l10n.companyDetailActiveLabel, style: Theme.of(context).textTheme.bodyLarge),
                ),
                if (_isTogglingActive)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                else
                  Switch(
                    value: company.isActive,
                    onChanged: _toggleActive,
                    activeThumbColor: AppColors.primary,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.companyDetailBranchesTitle, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final branch in company.branches) ...[
            _BranchTile(branch: branch),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({required this.branch});

  final CompanyBranchSummary branch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.onBackgroundMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(branch.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  branch.address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(
            text: branch.isActive ? l10n.companyManagementActiveBadge : l10n.companyManagementInactiveBadge,
            isPositive: branch.isActive,
          ),
        ],
      ),
    );
  }
}
