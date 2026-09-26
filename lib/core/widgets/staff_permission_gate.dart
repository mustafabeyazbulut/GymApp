import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/staff_permissions.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../features/auth/presentation/providers/staff_permissions_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Personel/yönetim ekranlarını aktif görevdeki role göre koruyan sarmalayıcı.
///
/// Menü (AppDrawer) yetkisiz girişleri zaten gizliyor, ama bir rotaya
/// doğrudan gidilirse (deep link, web URL, geri yığını) menü devre dışı
/// kalır. Rotalar app_router'da bu widget'la sarılır; [isAllowed] false ise
/// [child] hiç oluşturulmaz - yani ekranın CRUD aksiyonları render edilmez ve
/// initState'teki istekleri de atılmaz. Kullanıcı yüklenene kadar da ekran
/// oluşturulmaz (ekranlar currentUserProvider'ı initState'te senkron okuyor).
///
/// Neden go_router redirect değil: appRouter provider'ı izlediği her
/// provider değiştiğinde GoRouter'ı yeniden kurar (gezinti yığını sıfırlanır);
/// redirect'e currentUserProvider'ı bağlamak her /me yenilemesinde bunu
/// tetiklerdi ve kullanıcı yüklenirken geçerli bir deep link'i yanlışlıkla
/// geri çevirirdi. Backend her istekte yetkiyi yeniden kontrol eder; bu
/// sadece arayüz katmanıdır.
class StaffPermissionGate extends ConsumerWidget {
  const StaffPermissionGate({required this.isAllowed, required this.child, super.key});

  final bool Function(StaffPermissions permissions) isAllowed;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final permissions = ref.watch(staffPermissionsProvider);

    final me = currentUserAsync.asData?.value;
    if (me == null) {
      return Scaffold(
        appBar: AppBar(),
        body: currentUserAsync.hasError
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppLocalizations.of(context)!.commonError, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(currentUserProvider),
                        child: Text(AppLocalizations.of(context)!.commonRetry),
                      ),
                    ],
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (!isAllowed(permissions)) {
      return Scaffold(appBar: AppBar(), body: const _AccessDeniedState());
    }
    return child;
  }
}

class _AccessDeniedState extends StatelessWidget {
  const _AccessDeniedState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 40, color: AppColors.onBackgroundFaint),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.staffAccessDeniedTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.staffAccessDeniedBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
