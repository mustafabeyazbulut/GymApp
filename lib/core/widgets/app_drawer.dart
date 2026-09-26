import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/real_auth_repository.dart';
import '../../features/auth/domain/auth_exceptions.dart';
import '../../features/auth/domain/me_result.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../features/auth/presentation/providers/staff_permissions_provider.dart';
import '../../features/invitations/presentation/providers/invitations_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../locale/app_locale_provider.dart';
import '../providers/active_staff_assignment_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'otp_code_dialog.dart';

/// "Aktif Görev" seçicisindeki satır metni: "Firma · Şube · Rol". GymAdmin
/// firma genelinde çalıştığı için şube yerine "Firma geneli" yazılır; Sistem
/// Sahibi tek başına gösterilir. Şube adı gelmezse (eski backend) o parça
/// atlanır.
String activeTaskLabel(MeAssignment assignment, AppLocalizations l10n) {
  final String role;
  switch (assignment.role) {
    case 'SuperAdmin':
      return l10n.drawerActiveTaskSystemOwner;
    case 'GymAdmin':
      role = l10n.staffManagementRoleGymAdmin;
    case 'BranchManager':
      role = l10n.staffManagementRoleBranchManager;
    case 'Trainer':
      role = l10n.staffManagementRoleTrainer;
    default:
      role = assignment.role;
  }
  final branch = assignment.role == 'GymAdmin' ? l10n.drawerActiveTaskCompanyWide : assignment.branchName;
  return [assignment.companyName, branch, role].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
}

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
      // 409 ConcurrentUpdate: hesap başka bir oturumda değişti - güncel
      // veriyi çek, backend'in mesajını göster.
      if (exception is ConflictAuthException) ref.invalidate(currentUserProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.localizedMessage(context))));
    } finally {
      if (mounted) setState(() => _isChangingLanguage = false);
    }
  }

  // Birden fazla görevi olan kullanıcının (çok şubeli/çok firmalı personel,
  // personel ataması da olan Sistem Sahibi) şu an hangi görevle hareket
  // ettiğini seçmesi - seçim dioProvider'ın her isteğe eklediği
  // X-Active-Assignment-Id header'ını besler (bkz.
  // core/providers/active_staff_assignment_provider.dart). Menü, rota
  // korumaları ve personel ekranlarının verileri seçime göre yenilenir.
  Future<void> _pickActiveTask(List<MeAssignment> contexts, MeAssignment? current) async {
    final selected = await showDialog<MeAssignment>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return SimpleDialog(
          title: Text(l10n.drawerActiveTaskPickerTitle),
          children: [
            for (final assignment in contexts)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(assignment),
                child: Row(
                  children: [
                    Expanded(child: Text(activeTaskLabel(assignment, l10n))),
                    if (identical(assignment, current))
                      const Icon(Icons.check, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
          ],
        );
      },
    );

    // Id'siz atama (eski backend) seçim olarak saklanamaz.
    final selectedId = selected?.id;
    if (selectedId == null || !mounted) return;
    ref.read(activeStaffAssignmentProvider.notifier).select(selectedId);
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
    // Menü görünürlüğü "herhangi bir yerde personel mi" sorusuna değil,
    // AKTİF görevdeki role göre belirlenir (bkz. StaffPermissions).
    final permissions = ref.watch(staffPermissionsProvider);
    final activeTask = permissions.activeAssignment;
    final selectableContexts = currentUser?.selectableContexts ?? const <MeAssignment>[];
    final hasMultipleTasks = selectableContexts.length > 1;
    final pendingInvitationCount = ref.watch(pendingInvitationCountProvider);

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
                  if (permissions.canManageCompanies)
                    _DrawerItem(
                      icon: Icons.add_business_outlined,
                      label: l10n.drawerCompanyManagement,
                      onTap: () => closeThenPush('/admin/companies'),
                    ),
                  // Sistem Sahibi görevinde yüklenen içerik platformun genel
                  // içeriği olur (gym personeli kendi içeriğini İçerik
                  // Kütüphanesi'nden yükler).
                  if (permissions.canUploadPlatformContent)
                    _DrawerItem(
                      icon: Icons.upload_outlined,
                      label: l10n.drawerUploadPlatformContent,
                      onTap: () => closeThenPush('/content-library/upload'),
                    ),
                  if (hasMultipleTasks)
                    _DrawerItem(
                      icon: Icons.badge_outlined,
                      label: l10n.drawerActiveTaskLabel,
                      subtitle: activeTask == null ? null : activeTaskLabel(activeTask, l10n),
                      showChevron: true,
                      onTap: () => _pickActiveTask(selectableContexts, activeTask),
                    ),
                  if (permissions.canViewBranches)
                    _DrawerItem(
                      icon: Icons.storefront_outlined,
                      label: l10n.drawerBranchManagement,
                      onTap: () => closeThenPush('/staff/branches'),
                    ),
                  if (permissions.canManageStaff)
                    _DrawerItem(
                      icon: Icons.person_add_alt_outlined,
                      label: l10n.drawerAddStaffMember,
                      onTap: () => closeThenPush('/admin/add-staff-member'),
                    ),
                  if (permissions.canManageStaff)
                    _DrawerItem(
                      icon: Icons.groups_outlined,
                      label: l10n.drawerStaffManagement,
                      onTap: () => closeThenPush('/staff/members'),
                    ),
                  if (permissions.canManagePackages)
                    _DrawerItem(
                      icon: Icons.card_membership_outlined,
                      label: l10n.drawerPackageManagement,
                      onTap: () => closeThenPush('/staff/packages'),
                    ),
                  if (permissions.canCreateClassSession)
                    _DrawerItem(
                      icon: Icons.event_available_outlined,
                      label: l10n.drawerCreateClassSession,
                      onTap: () => closeThenPush('/staff/classes/create'),
                    ),
                  // Kapı/bölge kuralları firma geneli bir ayar - sadece GymAdmin.
                  if (permissions.canManageDoorAccess)
                    _DrawerItem(
                      icon: Icons.sensor_door_outlined,
                      label: l10n.drawerDoorAccess,
                      onTap: () => closeThenPush('/staff/door-access'),
                    ),
                  // Analiz ve raporlar gym'e özel - Sistem Sahibi gym'lerin
                  // günlük işlerine karışmadığı için (ana senaryo §4.6) sadece
                  // aktif firmada personel olanlar görür.
                  if (permissions.canViewGymReports)
                    _DrawerItem(
                      icon: Icons.analytics_outlined,
                      label: l10n.drawerAnalytics,
                      onTap: () => closeThenPush('/staff/analytics'),
                    ),
                  if (permissions.canViewGymReports)
                    _DrawerItem(
                      icon: Icons.summarize_outlined,
                      label: l10n.drawerReports,
                      onTap: () => closeThenPush('/staff/reports'),
                    ),
                  // Sadece aktif görev antrenörlük iken - başka bir görevdeki
                  // antrenörlük bu görevin programını açmaz.
                  if (permissions.canViewTrainerSchedule)
                    _DrawerItem(
                      icon: Icons.event_note_outlined,
                      label: l10n.drawerTrainerSchedule,
                      onTap: () => closeThenPush('/trainer/schedule'),
                    ),
                  if (hasMultipleTasks ||
                      permissions.canManageCompanies ||
                      permissions.hasManagementRole ||
                      permissions.canViewTrainerSchedule)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Divider(color: AppColors.border, height: 1),
                    ),
                  // Herkese açık - herhangi bir kullanıcı bir firmaya, şubeye
                  // veya pakete davet edilmiş olabilir; CreateCompany/
                  // AddStaffMember/CreatePackageAssignment hiçbiri Assignment/
                  // PackageAssignment'ı hemen oluşturmuyor, buradan onay
                  // gerekiyor. SMS koduyla onay Davetlerim ekranında ikincil yol.
                  _DrawerItem(
                    icon: Icons.mark_email_read_outlined,
                    label: l10n.drawerInvitations,
                    badgeCount: pendingInvitationCount,
                    onTap: () => closeThenPush('/invitations'),
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
    this.subtitle,
    this.trailingText,
    this.badgeCount = 0,
    this.isLoading = false,
    this.showChevron = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  // Etiketin altında tek satır, soluk ikincil bilgi (ör. aktif görevin
  // "Firma · Şube · Rol" metni) - sağdaki trailingText'e sığmayacak kadar uzun
  // değerler için.
  final String? subtitle;
  final String? trailingText;
  // > 0 ise sağda yeşil sayı rozeti - bekleyen bir işlem (ör. onay bekleyen
  // davet) olduğunu gösterir; yeşilin işlevsel kullanımı.
  final int badgeCount;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500, color: color ?? AppColors.onBackground),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackgroundFaint),
                        ),
                      ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onBackgroundFaint),
                )
              else if (badgeCount > 0)
                Container(
                  key: const ValueKey('drawerInvitationsBadge'),
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Text(
                    '$badgeCount',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700),
                  ),
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
