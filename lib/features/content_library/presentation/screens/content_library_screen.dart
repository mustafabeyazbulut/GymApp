import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/membership_context_provider.dart';
import '../../../../core/widgets/package_status_empty_state.dart';
import '../../../membership/domain/membership_summary.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/media_player_screen.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/staff_permissions_provider.dart';
import '../../domain/content_item.dart';
import '../providers/content_library_providers.dart';

/// Herkes görebilir - liste, erişemediği Premium içeriği de (upsell için)
/// kilitli olarak gösterir; gerçek erişim kontrolü oynatma sırasında
/// backend'de (GET /api/media/{id}) yeniden yapılır (bkz.
/// docs/superpowers/specs/2026-09-20-content-library-design.md).
class ContentLibraryScreen extends ConsumerStatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  ConsumerState<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends ConsumerState<ContentLibraryScreen> {
  // "Genel" (platform içeriği, herkese açık) varsayılan: paketsiz üye de
  // ekrana girer girmez bir şey görsün.
  ContentSource _source = ContentSource.platform;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Yükleme/yayından kaldırma aktif görevdeki personel rolüne bağlı - menüyle
    // aynı yetki matrisi (bkz. StaffPermissions).
    final permissions = ref.watch(staffPermissionsProvider);
    final canUpload = permissions.canUploadContent || permissions.canUploadPlatformContent;
    final itemsAsync = ref.watch(contentItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contentLibraryTitle),
        actions: [
          if (canUpload)
            IconButton(
              icon: const Icon(Icons.upload_outlined),
              tooltip: l10n.contentLibraryUploadButton,
              onPressed: () => context.push('/content-library/upload'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(l10n.contentLibraryTabPlatform),
                    selected: _source == ContentSource.platform,
                    onSelected: (_) => setState(() => _source = ContentSource.platform),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    label: Text(l10n.contentLibraryTabGym),
                    selected: _source == ContentSource.gym,
                    onSelected: (_) => setState(() => _source = ContentSource.gym),
                  ),
                ],
              ),
            ),
            Expanded(
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error is ApiException ? error.localizedMessage(context) : l10n.commonError,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton(
                          onPressed: () => ref.read(contentItemsProvider.notifier).refresh(),
                          child: Text(l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (allItems) {
                  final items = allItems.where((item) => item.source == _source).toList();
                  if (items.isEmpty) return _emptyState(context, l10n, permissions.activeAssignment == null);

                  return RefreshIndicator(
                    onRefresh: () => ref.read(contentItemsProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => _ContentItemTile(
                        item: items[index],
                        // Gym içeriğini personel, platform içeriğini Sistem
                        // Sahibi yönetir.
                        canManage: items[index].isPlatform
                            ? permissions.canUploadPlatformContent
                            : permissions.canUploadContent,
                        l10n: l10n,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n, bool isMemberOnly) {
    if (_source == ContentSource.gym && isMemberOnly) {
      // Görevi olmayan (sadece üye) kullanıcıya backend geçerli paketi yoksa
      // gym içeriğini boş döndürüyor - "içerik yok" yerine asıl neden
      // gösterilir. Personel içeriği görevi üzerinden görür.
      final memberships = ref.watch(membershipsProvider).asData?.value;
      final availability = memberships == null ? null : membershipAvailability(memberships);
      if (availability != null && availability.state != MembershipAvailabilityState.valid) {
        return PackageStatusEmptyState(availability: availability);
      }
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined, size: 40, color: AppColors.onBackgroundFaint),
            const SizedBox(height: AppSpacing.md),
            Text(
              _source == ContentSource.platform
                  ? l10n.contentLibraryPlatformEmptyMessage
                  : l10n.contentLibraryEmptyMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentItemTile extends ConsumerWidget {
  const _ContentItemTile({required this.item, required this.canManage, required this.l10n});

  final ContentItem item;
  final bool canManage;
  final AppLocalizations l10n;

  Future<void> _toggleActive(WidgetRef ref) =>
      ref.read(contentItemsProvider.notifier).setActive(id: item.id, isActive: !item.isActive);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isLocked = !item.hasAccess;

    return Opacity(
      opacity: isLocked || !item.isActive ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        // Material(transparency): ListTile arka planını/ink splash'ını en
        // yakın Material ata üzerine boyuyor - onu doğrudan renkli bir
        // Container'a sarmak Flutter'ın kendi uyarısına (ListTile background
        // color or ink splashes may be invisible) yol açıyordu.
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            leading: Icon(
              item.isVideo ? Icons.play_circle_outline : Icons.image_outlined,
              color: AppColors.primary,
            ),
            title: Text(item.title, style: textTheme.titleMedium),
            subtitle: item.description == null
                ? (item.isPremium ? Text(l10n.contentLibraryPremiumLabel) : null)
                : Text(item.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: isLocked
                ? const Icon(Icons.lock_outline, color: AppColors.onBackgroundFaint)
                : canManage
                    ? Switch(value: item.isActive, onChanged: (_) => _toggleActive(ref))
                    : null,
            onTap: isLocked
                ? () => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.contentLibraryLockedMessage)))
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MediaPlayerScreen(
                          mediaFileId: item.mediaFileId,
                          mediaContentType: item.mediaContentType,
                          title: item.title,
                        ),
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
