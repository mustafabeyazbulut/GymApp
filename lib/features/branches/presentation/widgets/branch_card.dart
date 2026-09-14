import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/branch.dart';
import 'status_pill.dart';

class BranchCard extends StatelessWidget {
  const BranchCard({required this.branch, super.key});

  final Branch branch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(branch.name, style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(branch.address, style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            StatusPill(isActive: branch.isActive),
          ],
        ),
      ),
    );
  }
}
