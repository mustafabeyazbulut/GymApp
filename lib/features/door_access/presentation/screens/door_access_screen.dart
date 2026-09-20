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
import '../providers/door_access_providers.dart';
import 'zone_detail_screen.dart';

/// Sadece staff (GymAdmin/BranchManager) görebilir - tamamen CRUD, hiçbir
/// canlı durum/log göstermez (gösterecek veri yok, bkz.
/// docs/superpowers/specs/2026-09-20-door-access-skeleton-design.md).
class DoorAccessScreen extends ConsumerStatefulWidget {
  const DoorAccessScreen({super.key});

  @override
  ConsumerState<DoorAccessScreen> createState() => _DoorAccessScreenState();
}

class _DoorAccessScreenState extends ConsumerState<DoorAccessScreen> {
  int? _selectedBranchId;
  bool _isLoadingBranches = false;
  String? _errorText;
  List<BranchOption>? _branchOptions;

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
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final branches = await ref.read(tenantRepositoryProvider).listBranches();
      if (!mounted) return;
      setState(() {
        _branchOptions = branches;
        _selectedBranchId ??= branches.isEmpty ? null : branches.first.id;
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  Future<void> _addZone(int branchId) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _promptForName(title: l10n.doorAccessAddZoneTitle);
    if (name == null || !mounted) return;
    try {
      await ref.read(zonesProvider(branchId).notifier).create(name);
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  Future<String?> _promptForName({required String title}) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: l10n.doorAccessNameLabel)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.accountDeletionCancelButton)),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.doorAccessAddButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeCompanyId = ref.watch(activeStaffCompanyIdProvider);
    final myAssignment = ref.watch(currentUserProvider).asData?.value.staffAssignmentFor(activeCompanyId);
    final fixedBranchId = myAssignment?.branchId;
    final branchId = fixedBranchId ?? _selectedBranchId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doorAccessTitle),
        actions: [
          if (branchId != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.doorAccessAddZoneTitle,
              onPressed: () => _addZone(branchId),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, l10n, fixedBranchId)),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, int? fixedBranchId) {
    if (fixedBranchId == null) {
      if (_isLoadingBranches) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      if (_errorText != null) {
        return Center(child: Text(_errorText!, textAlign: TextAlign.center));
      }
      final branches = _branchOptions ?? const <BranchOption>[];
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: DropdownButtonFormField<int?>(
              initialValue: _selectedBranchId,
              decoration: InputDecoration(labelText: l10n.addStaffMemberBranchLabel),
              items: branches.map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.name))).toList(),
              onChanged: (value) => setState(() => _selectedBranchId = value),
            ),
          ),
          if (_selectedBranchId != null) Expanded(child: _ZonesList(branchId: _selectedBranchId!, l10n: l10n)),
        ],
      );
    }

    return _ZonesList(branchId: fixedBranchId, l10n: l10n);
  }
}

class _ZonesList extends ConsumerWidget {
  const _ZonesList({required this.branchId, required this.l10n});

  final int branchId;
  final AppLocalizations l10n;

  Future<void> _delete(BuildContext context, WidgetRef ref, int zoneId) async {
    try {
      await ref.read(zonesProvider(branchId).notifier).delete(zoneId);
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesProvider(branchId));

    return zonesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stackTrace) => Center(
        child: Text(error is ApiException ? error.localizedMessage(context) : l10n.commonError, textAlign: TextAlign.center),
      ),
      data: (zones) {
        if (zones.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(l10n.doorAccessEmptyZonesMessage, style: Theme.of(context).textTheme.bodyMedium),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: zones.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final zone = zones[index];
            return Material(
              type: MaterialType.transparency,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: ListTile(
                  title: Text(zone.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _delete(context, ref, zone.id),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ZoneDetailScreen(zoneId: zone.id, zoneName: zone.name)),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
