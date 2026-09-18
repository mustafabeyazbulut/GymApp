import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../membership/data/real_membership_repository.dart';
import '../../../tenant_onboarding/data/real_tenant_repository.dart';

enum _InvitationKind { staff, package }

/// Backend'in davet-onay güvenlik modelinin (bkz. GymAppApi'nin
/// project-assignment-invitation-security.md'si) mobil tarafındaki tek giriş
/// noktası - CreateCompany/AddStaffMember/CreatePackageAssignment hiçbiri
/// Assignment/PackageAssignment'ı hemen oluşturmuyor, davet edilen kişinin
/// telefonuna gelen kodu BURADAN girip onaylaması gerekiyor. Daha önce bu
/// ekran hiç yoktu - yani hiçbir davet tamamlanamıyordu.
class ConfirmInvitationScreen extends ConsumerStatefulWidget {
  const ConfirmInvitationScreen({super.key});

  @override
  ConsumerState<ConfirmInvitationScreen> createState() => _ConfirmInvitationScreenState();
}

class _ConfirmInvitationScreenState extends ConsumerState<ConfirmInvitationScreen> {
  _InvitationKind _kind = _InvitationKind.staff;
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorText = l10n.commonFieldRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      if (_kind == _InvitationKind.staff) {
        await ref.read(tenantRepositoryProvider).confirmAssignmentInvitation(code);
      } else {
        await ref.read(membershipRepositoryProvider).confirmPackageAssignment(code);
      }
      if (!mounted) return;
      // Onay, çağıranın assignments/packageAssignments listesini değiştirir -
      // GetMe'den taze veri çekilmesi için invalidate et.
      ref.invalidate(currentUserProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.confirmInvitationSuccessMessage)));
      Navigator.of(context).pop();
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.confirmInvitationTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.confirmInvitationDescription, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.confirmInvitationKindLabel, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<_InvitationKind>(
                segments: [
                  ButtonSegment(value: _InvitationKind.staff, label: Text(l10n.confirmInvitationKindStaff)),
                  ButtonSegment(value: _InvitationKind.package, label: Text(l10n.confirmInvitationKindPackage)),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) => setState(() => _kind = selection.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: InputDecoration(labelText: l10n.confirmInvitationCodeLabel),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_errorText!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : Text(l10n.confirmInvitationSubmitButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
