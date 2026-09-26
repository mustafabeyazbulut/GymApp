import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/active_staff_assignment_provider.dart';
import '../../data/real_content_library_repository.dart';
import '../../domain/content_item.dart';

part 'content_library_providers.g.dart';

@riverpod
class ContentItemsNotifier extends _$ContentItemsNotifier {
  @override
  Future<List<ContentItem>> build() {
    // Personel kolu aktif görevin firma/şubesine göre listeleniyor - görev
    // değişince yenilenir.
    ref.watch(activeStaffAssignmentProvider);
    return ref.watch(contentLibraryRepositoryProvider).getContentItems();
  }

  Future<void> refresh() async {
    final repository = ref.read(contentLibraryRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(repository.getContentItems);
  }

  Future<void> upload({
    required String title,
    String? description,
    required String requiredAccessTier,
    int? branchId,
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    await ref.read(contentLibraryRepositoryProvider).createContentItem(
          title: title,
          description: description,
          requiredAccessTier: requiredAccessTier,
          branchId: branchId,
          filePath: filePath,
          fileName: fileName,
          mimeType: mimeType,
        );
    await refresh();
  }

  Future<void> setActive({required int id, required bool isActive}) async {
    await ref.read(contentLibraryRepositoryProvider).setContentItemActive(id: id, isActive: isActive);
    await refresh();
  }
}
