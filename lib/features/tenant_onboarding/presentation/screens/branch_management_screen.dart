import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/active_staff_assignment_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/staff_permissions.dart';
import '../../../auth/presentation/providers/staff_permissions_provider.dart';
import '../../data/real_tenant_repository.dart';
import '../../domain/branch_summary.dart';
import '../widgets/branch_form_sheet.dart';

/// Bir GymAdmin'in kendi şirketinin şubelerini oluşturması/yeniden
/// adlandırması/kapatması için - backend'de uzun zamandır vardı
/// (project-branch-ownership-flow.md'nin tarif ettiği "önce şube, sonra
/// personel" akışı) ama hiçbir mobil giriş noktası yoktu. BranchManager da
/// bu ekranı görebilir ama sadece kendi şubesini ve salt-okunur - şube
/// oluşturma/kapatma backend'de zaten sadece GymAdmin/SuperAdmin'e açık.
class BranchManagementScreen extends ConsumerStatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  ConsumerState<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends ConsumerState<BranchManagementScreen> {
  List<BranchSummary>? _branches;
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
      final branches = await ref.read(tenantRepositoryProvider).getManagedBranches();
      if (!mounted) return;
      setState(() => _branches = branches);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateBranch(int companyId) async {
    await showBranchFormSheet(context, companyId: companyId);
    if (!mounted) return;
    _load();
  }

  Future<void> _openEditBranch(int companyId, BranchSummary branch) async {
    await showBranchFormSheet(context, companyId: companyId, branch: branch);
    if (!mounted) return;
    _load();
  }

  Future<void> _confirmAndDeactivate(BranchSummary branch) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.branchDeactivateConfirmTitle),
        content: Text(l10n.branchDeactivateConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountDeletionCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.branchDeactivateConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(tenantRepositoryProvider).setBranchActive(branchId: branch.id, isActive: false);
      if (!mounted) return;
      _load();
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permissions = ref.watch(staffPermissionsProvider);
    // Aktif görev değişince liste o görevin şubeleriyle yeniden yüklenir.
    ref.listen(activeStaffAssignmentProvider, (_, _) => _load());
    final canManage = permissions.canManageBranches;
    final companyId = permissions.activeAssignment?.companyId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.branchManagementTitle),
        actions: [
          if (canManage && companyId != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.branchManagementAddButton,
              onPressed: () => _openCreateBranch(companyId),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, l10n, permissions)),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, StaffPermissions permissions) {
    final canManage = permissions.canManageBranches;
    if (_isLoading && _branches == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_errorText != null && _branches == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
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

    // Savunma katmanı: BranchManager sadece atandığı şubeyi görür (ana senaryo
    // §4.4) - backend'in şube filtresine ek olarak istemci tarafında da
    // uygulanır.
    final branches = (_branches ?? const <BranchSummary>[]).where((b) => permissions.canSeeBranch(b.id)).toList();
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: branches.isEmpty
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
                          l10n.branchManagementEmptyMessage,
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
              itemCount: branches.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final branch = branches[index];
                return _BranchTile(
                  branch: branch,
                  canManage: canManage,
                  onTap: canManage ? () => _openEditBranch(branch.companyId, branch) : null,
                  onDeactivate: canManage ? () => _confirmAndDeactivate(branch) : null,
                );
              },
            ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({required this.branch, required this.canManage, this.onTap, this.onDeactivate});

  final BranchSummary branch;
  final bool canManage;
  final VoidCallback? onTap;
  final VoidCallback? onDeactivate;

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
              const Icon(Icons.location_on_outlined, color: AppColors.onBackgroundMuted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(branch.name, style: Theme.of(context).textTheme.titleMedium),
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
              if (canManage && branch.isActive && onDeactivate != null)
                IconButton(
                  icon: const Icon(Icons.block, size: 18, color: AppColors.error),
                  tooltip: l10n.branchDeactivateButton,
                  onPressed: onDeactivate,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
