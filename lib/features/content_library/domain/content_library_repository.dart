import 'content_item.dart';

abstract interface class ContentLibraryRepository {
  // Herkes çağırabilir - backend, staff/Member görünürlüğünü kendi
  // tarafında filtreliyor (bkz. GetContentItemsQueryHandler).
  Future<List<ContentItem>> getContentItems();

  // Sadece StaffManagement (GymAdmin/BranchManager/SuperAdmin).
  // branchId null = firmanın tüm şubelerinde görünür.
  Future<ContentItem> createContentItem({
    required String title,
    String? description,
    required String requiredAccessTier,
    int? branchId,
    required String filePath,
    required String fileName,
    required String mimeType,
  });

  Future<void> setContentItemActive({required int id, required bool isActive});

  // Görsel için: byte'ları indirip Image.memory ile göstermek üzere (dio'nun
  // interceptor'ı Authorization header'ını otomatik ekliyor).
  Future<List<int>> downloadMediaBytes(int mediaFileId);

  // Video için: video_player'ın networkUrl'i kendi HTTP istemcisini
  // kullanıyor (dio'nun interceptor'ından geçmiyor), bu yüzden URL + auth
  // header'ı ayrıca sağlanır.
  String mediaUrl(int mediaFileId);
  Future<Map<String, String>> mediaAuthHeaders();

  // video_player erişim reddini (ör. 403 ForbiddenViewMedia) okunabilir bir
  // hata olarak vermediği için oynatıcı başlatılmadan önce erişim dio
  // üzerinden kontrol edilir. Erişim yoksa backend'in mesajıyla ApiException
  // fırlatır; varsa gövdeyi indirmeden tamamlanır.
  Future<void> ensureMediaAccessible(int mediaFileId);
}
