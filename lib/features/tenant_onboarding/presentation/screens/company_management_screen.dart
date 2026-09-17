import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/real_tenant_repository.dart';
import '../../domain/company_summary.dart';

/// Super Admin's entry point for company administration - lists every
/// company (name, branch count, active/inactive), lets them open one to
/// rename it or toggle it active, and start a new one via the app bar
/// action. Replaces going straight from the drawer into a bare create-company
/// form (feedback: there should be somewhere to see and manage the
/// companies that already exist, not just add new ones blind).
class CompanyManagementScreen extends ConsumerStatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  ConsumerState<CompanyManagementScreen> createState() => _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends ConsumerState<CompanyManagementScreen> {
  List<CompanyListItem>? _companies;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final companies = await ref.read(tenantRepositoryProvider).listCompanies();
      if (!mounted) return;
      setState(() => _companies = companies);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateCompany() async {
    await context.push('/admin/create-company');
    if (!mounted) return;
    _load();
  }

  Future<void> _openCompanyDetail(int companyId) async {
    await context.push('/admin/companies/$companyId');
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companyManagementTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: l10n.companyManagementAddButton,
            onPressed: _openCreateCompany,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading && _companies == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_errorText != null && _companies == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            _errorText!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
          ),
        ),
      );
    }

    final companies = _companies ?? const <CompanyListItem>[];
    return RefreshIndicator(
      onRefresh: _load,
      child: companies.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(l10n.companyManagementEmptyMessage, textAlign: TextAlign.center),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: companies.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _CompanyTile(
                company: companies[index],
                onTap: () => _openCompanyDetail(companies[index].id),
              ),
            ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.company, required this.onTap});

  final CompanyListItem company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.companyManagementBranchCount(company.branchCount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
                    ),
                  ],
                ),
              ),
              if (!company.isActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    l10n.companyManagementInactiveBadge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              const Icon(Icons.chevron_right, color: AppColors.onBackgroundFaint),
            ],
          ),
        ),
      ),
    );
  }
}
