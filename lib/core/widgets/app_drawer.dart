import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/real_auth_repository.dart';
import '../../features/auth/domain/auth_exceptions.dart';
import '../../features/auth/domain/me_result.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../locale/app_locale_provider.dart';
import '../providers/active_staff_company_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'otp_code_dialog.dart';

/// Uygulamanın yan navigasyon çekmecesi; her shell dalında ortak kullanılır
/// (bkz. `appShellScaffoldKey`) ve header'daki menü butonundan açılır.
/// Yalnızca header veya alt navigasyonda (Home/Classes/Progress/Profile,
/// Notifications'ın kendi zil ikonu) zaten erişilebilir olmayan hedefleri
/// içerir — hesap ayarları (Profile ekranından buraya taşındı) ve çıkış yap.
class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isChangingLanguage = false;
  bool _isFreezingAccount = false;
  bool _isDeletingAccount = false;

  String _languageDisplayName(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' ? 'English' : 'Türkçe';

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.settingsLanguagePickerTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('tr'),
            child: const Text('Türkçe'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop('en'),
            child: const Text('English'),
          ),
        ],
      ),
    );

    if (selected == null || !mounted) return;

    // Uygulama dili tamamen istemci tarafı bir tercih - sunucuya
    // senkronizasyon (backend mesajlarının da aynı dilde gelmesi için)
    // başarısız olsa bile arayüz dili hemen değişmeli. Bu ikisini
    // birbirine bağlamak (PATCH önce, setLocale sadece başarılıysa)
    // bağlantı sorunu yaşayan bir kullanıcının hiçbir zaman arayüz dilini
    // değiştirememesine yol açıyordu.
    ref.read(appLocaleProvider.notifier).setLocale(Locale(selected));
    Navigator.of(context).pop();

    setState(() => _isChangingLanguage = true);
    try {
      await ref.read(authRepositoryProvider).updatePreferredLanguage(selected);
    } on AuthException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    } finally {
      if (mounted) setState(() => _isChangingLanguage = false);
    }
  }

  // Çok şirketli bir GymAdmin/BranchManager'ın şu an personel yönetimi
  // için hangi şirketi "aktif" olarak kullandığını seçmesi - seçim
  // dioProvider'ın her isteğe eklediği X-Active-Company-Id header'ını
  // besler (bkz. core/providers/active_staff_company_provider.dart).
  Future<void> _pickActiveCompany(List<MeAssignment> staffAssignments, int? currentCompanyId) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(AppLocalizations.of(dialogContext)!.drawerActiveCompanyPickerTitle),
        children: [
          for (final assignment in staffAssignments)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(assignment.companyId),
              child: Row(
                children: [
                  Expanded(child: Text(assignment.companyName ?? '')),
                  if (assignment.companyId == currentCompanyId)
                    const Icon(Icons.check, size: 18, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );

    if (selected == null || !mounted) return;
    ref.read(activeStaffCompanyIdProvider.notifier).select(selected);
  }

  Future<void> _confirmAndFreezeAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountFreezeConfirmTitle),
        content: Text(l10n.accountFreezeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountDeletionCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accountFreezeConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isFreezingAccount = true);
    try {
      await ref.read(authRepositoryProvider).requestFreezeOtp();
      if (!mounted) return;
      final code = await showOtpCodeDialog(
        context: context,
        title: l10n.accountActionOtpTitle,
        message: l10n.accountActionOtpMessage,
        codeLabel: l10n.accountActionOtpCodeLabel,
        submitLabel: l10n.accountActionOtpSubmitButton,
        cancelLabel: l10n.accountActionOtpCancelButton,
      );
      if (code == null || !mounted) return;

      await ref.read(authRepositoryProvider).freezeAccount(code: code);
      if (!mounted) return;
      // freezeAccount() sunucu tarafında zaten tüm refresh token'ları iptal
      // etti; logOut() ise artık geçersiz olan yerel kopyayı temizliyor.
      await ref.read(authStateProvider.notifier).logOut();
    } on AuthException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    } finally {
      if (mounted) setState(() => _isFreezingAccount = false);
    }
  }

  Future<void> _confirmAndDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountDeletionConfirmTitle),
        content: Text(l10n.accountDeletionConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountDeletionCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accountDeletionConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await ref.read(authRepositoryProvider).requestDeleteAccountOtp();
      if (!mounted) return;
      final code = await showOtpCodeDialog(
        context: context,
        title: l10n.accountActionOtpTitle,
        message: l10n.accountActionOtpMessage,
        codeLabel: l10n.accountActionOtpCodeLabel,
        submitLabel: l10n.accountActionOtpSubmitButton,
        cancelLabel: l10n.accountActionOtpCancelButton,
      );
      if (code == null || !mounted) return;

      await ref.read(authRepositoryProvider).deleteAccount(code: code);
      if (!mounted) return;
      // deleteAccount() zaten token deposunu temizliyor; logOut() onu tekrar
      // temizliyor. Zaten temizlenmiş bir depoda ikinci bir clear() çağrısının
      // hiçbir etkisi olmaması (no-op) beklenir.
      await ref.read(authStateProvider.notifier).logOut();
    } on AuthException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final activeCompanyId = ref.watch(activeStaffCompanyIdProvider);
    final activeStaffAssignment = currentUser?.staffAssignmentFor(activeCompanyId);
    final hasMultipleStaffCompanies = (currentUser?.staffAssignments.length ?? 0) > 1;

    void closeThenPush(String location) {
      // Drawer'ın GoRouter'ı: bu widget'ın kendi context'i degil, cunku
      // Navigator.pop(context) burada drawer'i kapatma animasyonunu
      // BASLATIYOR (senkron donuyor, animasyonu BEKLEMIYOR) - hemen
      // ardindan context.push cagrilirsa yeni sayfa drawer'i tam kapanma
      // animasyonu bitmeden ustune biniyor. Flutter, tamamen ortulmus bir
      // route'un animasyonunu duraklatiyor - yani drawer'in kapanma
      // animasyonu YARIM kalip DURUYOR, geri tusuna basilip bu sayfa
      // tekrar gorunur olunca da KALDIGI YERDEN devam ediyor. Sonuc:
      // kullanici "geri" tusuna bastiginda beklenmedik sekilde drawer'in
      // kapanma animasyonunu goruyor - "asiri kotu kalitesiz bir izlenim".
      // Router referansini ONCE (drawer widget'i hala tam mounted'ken)
      // aliyoruz cunku push, drawer kapanma animasyonu bittikten (asagidaki
      // gecikme kadar) SONRA calisiyor - o noktada bu widget'in kendi
      // context'i coktan dispose olmus olabilir, ama GoRouter nesnesi
      // (uygulama kokunde yasiyor) hala gecerli.
      final router = GoRouter.of(context);
      Navigator.pop(context);
      Future.delayed(const Duration(milliseconds: 250), () => router.push(location));
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _initial(currentUser?.fullName),
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.fullName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          currentUser?.email ?? currentUser?.phone ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                children: [
                  if (currentUser?.isSuperAdmin ?? false)
                    _DrawerItem(
                      icon: Icons.add_business_outlined,
                      label: l10n.drawerCompanyManagement,
                      onTap: () => closeThenPush('/admin/companies'),
                    ),
                  if (hasMultipleStaffCompanies)
                    _DrawerItem(
                      icon: Icons.apartment_outlined,
                      label: l10n.drawerActiveCompanyLabel,
                      trailingText: activeStaffAssignment?.companyName,
                      showChevron: true,
                      onTap: () =>
                          _pickActiveCompany(currentUser!.staffAssignments, activeStaffAssignment?.companyId),
                    ),
                  if (currentUser?.staffAssignment != null)
                    _DrawerItem(
                      icon: Icons.storefront_outlined,
                      label: l10n.drawerBranchManagement,
                      onTap: () => closeThenPush('/staff/branches'),
                    ),
                  if (currentUser?.staffAssignment != null)
                    _DrawerItem(
                      icon: Icons.person_add_alt_outlined,
                      label: l10n.drawerAddStaffMember,
                      // Birden fazla şirket varsa hangi şirketi hedeflediğini
                      // görünür kıl - artık gerçekten yukarıdaki "Aktif
                      // Şirket" seçimini yansıtıyor (bkz.
                      // MeResult.staffAssignmentFor, X-Active-Company-Id).
                      trailingText: hasMultipleStaffCompanies ? activeStaffAssignment?.companyName : null,
                      onTap: () => closeThenPush('/admin/add-staff-member'),
                    ),
                  if (currentUser?.staffAssignment != null)
                    _DrawerItem(
                      icon: Icons.groups_outlined,
                      label: l10n.drawerStaffManagement,
                      onTap: () => closeThenPush('/staff/members'),
                    ),
                  if (currentUser?.staffAssignment != null)
                    _DrawerItem(
                      icon: Icons.card_membership_outlined,
                      label: l10n.drawerPackageManagement,
                      onTap: () => closeThenPush('/staff/packages'),
                    ),
                  if (currentUser?.staffAssignment != null)
                    _DrawerItem(
                      icon: Icons.event_available_outlined,
                      label: l10n.drawerCreateClassSession,
                      onTap: () => closeThenPush('/staff/classes/create'),
                    ),
                  if (currentUser?.staffAssignment != null)
                    _DrawerItem(
                      icon: Icons.sensor_door_outlined,
                      label: l10n.drawerDoorAccess,
                      onTap: () => closeThenPush('/staff/door-access'),
                    ),
                  // Analiz ekranı SuperAdmin'i de kapsıyor (backend'in
                  // StaffManagement policy'si zaten BranchManager/GymAdmin/
                  // SuperAdmin'i kapsıyor) - sadece `staffAssignment != null`
                  // koşulu SuperAdmin'i (staffAssignment'ı hep null döner)
                  // dışarıda bırakırdı, bu yüzden isSuperAdmin ile OR'lanıyor
                  // (üstteki "Yeni Firma Ekle" girişiyle aynı desen).
                  if ((currentUser?.isSuperAdmin ?? false) || currentUser?.staffAssignment != null)
                    _DrawerItem(
                      icon: Icons.analytics_outlined,
                      label: l10n.drawerAnalytics,
                      onTap: () => closeThenPush('/staff/analytics'),
                    ),
                  if (currentUser?.isTrainer ?? false)
                    _DrawerItem(
                      icon: Icons.event_note_outlined,
                      label: l10n.drawerTrainerSchedule,
                      onTap: () => closeThenPush('/trainer/schedule'),
                    ),
                  if ((currentUser?.isSuperAdmin ?? false) ||
                      currentUser?.staffAssignment != null ||
                      (currentUser?.isTrainer ?? false))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Divider(color: AppColors.border, height: 1),
                    ),
                  // Herkese açık - herhangi bir kullanıcı bir firmaya, şubeye
                  // veya pakete davet edilmiş olabilir; CreateCompany/
                  // AddStaffMember/CreatePackageAssignment hiçbiri Assignment/
                  // PackageAssignment'ı hemen oluşturmuyor, buradan onay
                  // gerekiyor.
                  _DrawerItem(
                    icon: Icons.mark_email_read_outlined,
                    label: l10n.drawerConfirmInvitation,
                    onTap: () => closeThenPush('/confirm-invitation'),
                  ),
                  // Herkese açık - liste, staff/Member görünürlüğünü kendi
                  // tarafında filtreliyor (bkz. GetContentItemsQueryHandler).
                  _DrawerItem(
                    icon: Icons.video_library_outlined,
                    label: l10n.drawerContentLibrary,
                    onTap: () => closeThenPush('/content-library'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Divider(color: AppColors.border, height: 1),
                  ),
                  _DrawerItem(
                    icon: Icons.language,
                    label: l10n.settingsLanguageLabel,
                    trailingText: _languageDisplayName(context),
                    isLoading: _isChangingLanguage,
                    // closeThenRun KULLANMA - çekmece burada hemen kapatılırsa
                    // (Navigator.pop), _pickLanguage'ın showDialog'unu
                    // beklerken _AppDrawerState çoktan dispose olmuş oluyor;
                    // dialogdan dönen sonuçtaki "if (!mounted) return" bu
                    // yüzden HER ZAMAN erken çıkıyor ve setLocale hiç
                    // çalışmıyordu. Çekmece, dialog süresince açık kalmalı.
                    onTap: _isChangingLanguage ? null : _pickLanguage,
                  ),
                  _DrawerItem(
                    icon: Icons.pause_circle_outline,
                    label: l10n.accountFreezeButton,
                    showChevron: true,
                    isLoading: _isFreezingAccount,
                    // Aynı neden: onay dialogu/OTP dialogu süresince çekmece
                    // açık kalmalı, bkz. yukarıdaki dil seçici notu.
                    onTap: _isFreezingAccount ? null : _confirmAndFreezeAccount,
                  ),
                  _DrawerItem(
                    icon: Icons.delete_outline,
                    label: l10n.accountDeletionButton,
                    color: AppColors.error,
                    showChevron: true,
                    isLoading: _isDeletingAccount,
                    onTap: _isDeletingAccount ? null : _confirmAndDeleteAccount,
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: _DrawerItem(
                icon: Icons.logout,
                label: l10n.commonLogOut,
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authStateProvider.notifier).logOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initial(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    return fullName.trim()[0].toUpperCase();
  }
}

/// Tıklanabilir bir çekmece satırı — ikon, etiket ve ardından ya hiçbir şey,
/// ya bir chevron, ya bir sondaki değer + chevron (ör. geçerli dil) ya da
/// [isLoading] sırasında bir spinner gösterir.
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.trailingText,
    this.isLoading = false,
    this.showChevron = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final String? trailingText;
  final bool isLoading;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color ?? AppColors.onBackgroundMuted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: color ?? AppColors.onBackground),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onBackgroundFaint),
                )
              else if (trailingText != null || showChevron)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trailingText != null) ...[
                      Text(
                        trailingText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.onBackgroundFaint),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
