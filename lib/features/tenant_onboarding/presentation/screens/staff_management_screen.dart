import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/active_staff_assignment_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/real_tenant_repository.dart';
import '../../domain/staff_member_summary.dart';

/// Bir GymAdmin/BranchManager'ın kendi personelini (GymAdmin/BranchManager/
/// Trainer) görüp kaldırabilmesi için - DELETE /api/assignments/{id} uzun
/// zamandır vardı ama personelin kim olduğunu göremeden hedef id'yi hiçbir
/// zaman bulamıyordu.
class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  List<StaffMemberSummary>? _staff;
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
      final staff = await ref.read(tenantRepositoryProvider).getStaffMembers();
      if (!mounted) return;
      setState(() => _staff = staff);
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddStaffMember() async {
    await context.push('/admin/add-staff-member');
    if (!mounted) return;
    _load();
  }

  Future<void> _confirmAndRemove(StaffMemberSummary member) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.staffManagementRemoveConfirmTitle(member.fullName)),
        content: Text(l10n.staffManagementRemoveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountDeletionCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.staffManagementRemoveConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(tenantRepositoryProvider).removeAssignment(member.assignmentId);
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
    // Aktif görev değişince liste o görevin personeliyle yeniden yüklenir.
    ref.listen(activeStaffAssignmentProvider, (_, _) => _load());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staffManagementTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined),
            tooltip: l10n.drawerAddStaffMember,
            onPressed: _openAddStaffMember,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, l10n)),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading && _staff == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_errorText != null && _staff == null) {
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

    final staff = _staff ?? const <StaffMemberSummary>[];
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: staff.isEmpty
          ? ListView(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxl * 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_outlined, size: 40, color: AppColors.onBackgroundFaint),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.staffManagementEmptyMessage,
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
              itemCount: staff.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _StaffTile(
                member: staff[index],
                onRemove: () => _confirmAndRemove(staff[index]),
              ),
            ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.member, required this.onRemove});

  final StaffMemberSummary member;
  final VoidCallback onRemove;

  String _roleLabel(AppLocalizations l10n) => switch (member.role) {
        'GymAdmin' => l10n.staffManagementRoleGymAdmin,
        'BranchManager' => l10n.staffManagementRoleBranchManager,
        _ => l10n.staffManagementRoleTrainer,
      };

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  member.branchName == null
                      ? _roleLabel(l10n)
                      : '${_roleLabel(l10n)} · ${member.branchName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted),
                ),
                Text(
                  member.phone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_remove_outlined, color: AppColors.error),
            tooltip: l10n.staffManagementRemoveButton,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
