import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/membership_summary.dart';

/// Birden fazla PackageAssignment'ı olan bir kullanıcının hangisini
/// görüntülediğini seçtiği ortak switcher — Home, Classes ve Membership
/// ekranlarının üçü de aynı [selectedId]/seçim mantığını paylaşır (bkz.
/// core/providers/membership_context_provider.dart). Tek üyeliği olan bir
/// kullanıcı için hiçbir şey render etmez.
class MembershipSwitcher extends StatelessWidget {
  const MembershipSwitcher({
    required this.label,
    required this.memberships,
    required this.selectedId,
    required this.onSelect,
    super.key,
  });

  final String label;
  final List<MembershipSummary> memberships;
  final int selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (memberships.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: memberships
              .map((m) => ChoiceChip(
                    label: Text('${m.companyName} · ${m.packageName}'),
                    selected: m.id == selectedId,
                    onSelected: (_) => onSelect(m.id),
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
