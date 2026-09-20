import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/zone.dart';
import '../providers/door_access_providers.dart';

/// Bir bölgenin kapıları + erişim kuralları - basit liste + ekle/sil,
/// tamamen CRUD, hiçbir canlı durum/log göstermez (bkz.
/// docs/superpowers/specs/2026-09-20-door-access-skeleton-design.md).
class ZoneDetailScreen extends ConsumerWidget {
  const ZoneDetailScreen({required this.zoneId, required this.zoneName, super.key});

  final int zoneId;
  final String zoneName;

  Future<void> _addDoor(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.doorAccessAddDoorTitle),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: l10n.doorAccessNameLabel)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.accountDeletionCancelButton)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: Text(l10n.doorAccessAddButton)),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      await ref.read(doorsProvider(zoneId).notifier).create(name);
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  Future<void> _addRule(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (dialogContext) => _AddRuleDialog(l10n: l10n),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(zoneAccessRulesProvider(zoneId).notifier).create(ruleType: result.$1, ruleValue: result.$2);
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final doorsAsync = ref.watch(doorsProvider(zoneId));
    final rulesAsync = ref.watch(zoneAccessRulesProvider(zoneId));

    return Scaffold(
      appBar: AppBar(title: Text(zoneName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SectionHeader(title: l10n.doorAccessDoorsTitle, onAdd: () => _addDoor(context, ref)),
            const SizedBox(height: AppSpacing.sm),
            doorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (error, stackTrace) => Text(error is ApiException ? error.localizedMessage(context) : l10n.commonError),
              data: (doors) => doors.isEmpty
                  ? Text(l10n.doorAccessEmptyDoorsMessage, style: Theme.of(context).textTheme.bodyMedium)
                  : Column(
                      children: [
                        for (final door in doors)
                          ListTile(
                            title: Text(door.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () async {
                                try {
                                  await ref.read(doorsProvider(zoneId).notifier).delete(door.id);
                                } on ApiException catch (exception) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
                                }
                              },
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(title: l10n.doorAccessRulesTitle, onAdd: () => _addRule(context, ref)),
            const SizedBox(height: AppSpacing.sm),
            rulesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (error, stackTrace) => Text(error is ApiException ? error.localizedMessage(context) : l10n.commonError),
              data: (rules) => rules.isEmpty
                  ? Text(l10n.doorAccessEmptyRulesMessage, style: Theme.of(context).textTheme.bodyMedium)
                  : Column(
                      children: [
                        for (final rule in rules)
                          ListTile(
                            title: Text(_ruleLabel(rule, l10n)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () async {
                                try {
                                  await ref.read(zoneAccessRulesProvider(zoneId).notifier).delete(rule.id);
                                } on ApiException catch (exception) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
                                }
                              },
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _ruleLabel(ZoneAccessRule rule, AppLocalizations l10n) =>
      rule.ruleValue == null ? rule.ruleType : '${rule.ruleType}: ${rule.ruleValue}';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        IconButton(icon: const Icon(Icons.add), onPressed: onAdd),
      ],
    );
  }
}

class _AddRuleDialog extends StatefulWidget {
  const _AddRuleDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_AddRuleDialog> createState() => _AddRuleDialogState();
}

class _AddRuleDialogState extends State<_AddRuleDialog> {
  String _ruleType = 'AllActiveMembers';
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.doorAccessAddRuleTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _ruleType,
            decoration: InputDecoration(labelText: l10n.doorAccessRuleTypeLabel),
            items: const [
              DropdownMenuItem(value: 'AllActiveMembers', child: Text('AllActiveMembers')),
              DropdownMenuItem(value: 'Gender', child: Text('Gender')),
              DropdownMenuItem(value: 'Role', child: Text('Role')),
              DropdownMenuItem(value: 'PackageCategory', child: Text('PackageCategory')),
            ],
            onChanged: (value) => setState(() => _ruleType = value!),
          ),
          if (_ruleType != 'AllActiveMembers')
            TextField(controller: _valueController, decoration: InputDecoration(labelText: l10n.doorAccessRuleValueLabel)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.accountDeletionCancelButton)),
        TextButton(
          onPressed: () => Navigator.of(context).pop((
            _ruleType,
            _ruleType == 'AllActiveMembers' ? null : _valueController.text.trim(),
          )),
          child: Text(l10n.doorAccessAddButton),
        ),
      ],
    );
  }
}
