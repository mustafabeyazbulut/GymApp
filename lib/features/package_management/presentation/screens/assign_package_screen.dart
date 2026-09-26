import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/phone_number_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/package_providers.dart';

/// Bir paket şablonunu bir üyeye atamak için - backend'de
/// CreatePackageAssignmentCommand zaten vardı (kendi SMS onay akışıyla,
/// bkz. ConfirmInvitationScreen'in "package" segmenti) ama hiçbir mobil
/// giriş noktası yoktu.
class AssignPackageScreen extends ConsumerStatefulWidget {
  const AssignPackageScreen({super.key});

  @override
  ConsumerState<AssignPackageScreen> createState() => _AssignPackageScreenState();
}

class _AssignPackageScreenState extends ConsumerState<AssignPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedPackageId;
  String? _phone;
  bool _isSubmitting = false;
  String? _errorText;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackageId == null || _phone == null || _phone!.trim().isEmpty) {
      setState(() => _errorText = l10n.commonFieldRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref
          .read(packageActionsProvider.notifier)
          .assignPackage(packageId: _selectedPackageId!, memberPhone: _phone!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.assignPackageSuccessMessage)));
      Navigator.of(context).pop();
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorText = exception.localizedMessage(context));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final packagesAsync = ref.watch(packagesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assignPackageTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                packagesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (error, stackTrace) => Text(
                    error is ApiException ? error.localizedMessage(context) : l10n.commonError,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  data: (packages) {
                    final activePackages = packages.where((p) => p.isActive).toList();
                    _selectedPackageId ??= activePackages.isNotEmpty ? activePackages.first.id : null;
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedPackageId,
                      decoration: InputDecoration(labelText: l10n.assignPackagePackageLabel),
                      items: activePackages
                          .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedPackageId = value),
                      validator: (value) => value == null ? l10n.commonFieldRequired : null,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                PhoneNumberField(
                  labelText: l10n.assignPackageMemberPhoneLabel,
                  onChanged: (phone) => _phone = phone,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    l10n.assignPackageMemberPhoneHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: AppSpacing.md),
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
                      : Text(l10n.assignPackageSubmitButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
