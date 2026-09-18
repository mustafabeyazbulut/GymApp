import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/real_tenant_repository.dart';
import '../../domain/company_summary.dart';

/// Super Admin'in şirket yönetimi için giriş noktası - her şirketi
/// (ad, şube sayısı, aktif/pasif) listeler, birini açıp adını değiştirmesine
/// veya aktifliğini değiştirmesine izin verir ve app bar action'ı üzerinden
/// yeni bir şirket başlatılmasını sağlar. Drawer'dan doğrudan boş bir
/// create-company formuna gitmenin yerini alır (geri bildirim: sadece kör
/// bir şekilde yeni şirket eklemek değil, mevcut şirketleri görüp
/// yönetebileceğimiz bir yer olmalı).
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
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorText!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: _load, child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      );
    }

    final companies = _companies ?? const <CompanyListItem>[];
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: companies.isEmpty
          ? ListView(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxl * 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 40, color: AppColors.onBackgroundFaint),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.companyManagementEmptyMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: companies.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
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
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.storefront_outlined, color: AppColors.onBackgroundMuted),
              const SizedBox(width: AppSpacing.md),
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
              const SizedBox(width: AppSpacing.sm),
              StatusPill(
                text: company.isActive ? l10n.companyManagementActiveBadge : l10n.companyManagementInactiveBadge,
                isPositive: company.isActive,
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.onBackgroundFaint),
            ],
          ),
        ),
      ),
    );
  }
}
