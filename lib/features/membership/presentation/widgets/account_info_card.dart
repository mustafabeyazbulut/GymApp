import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/me_result.dart';
import 'change_password_sheet.dart';
import 'edit_profile_sheet.dart';

/// "Profil" sekmesinin her zaman (bir üyelik olsun ya da olmasın) gösterdiği
/// tek bölüm - ad/telefon/e-posta ve düzenleme/şifre değiştirme eylemleri.
/// Üyelik/ödeme geçmişi bundan sonra, MembershipScreen tarafından ayrıca
/// eklenir (bkz. o dosyanın "Hesap ayarları AppDrawer'a taşındı" notu -
/// dil/dondurma/silme burada DEĞİL, kasıtlı olarak drawer'da kalıyor).
class AccountInfoCard extends StatelessWidget {
  const AccountInfoCard({super.key, required this.user});

  final MeResult user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.profileAccountInfoLabel, style: textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(user.fullName, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          _InfoRow(icon: Icons.phone_outlined, text: user.phone),
          if (user.email != null && user.email!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(icon: Icons.email_outlined, text: user.email!),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => showEditProfileSheet(context, currentFullName: user.fullName, currentEmail: user.email),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.profileEditButton),
              ),
              OutlinedButton.icon(
                onPressed: () => showChangePasswordSheet(context),
                icon: const Icon(Icons.lock_outline, size: 18),
                label: Text(l10n.profileChangePasswordButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onBackgroundFaint),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundMuted)),
      ],
    );
  }
}
