import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/real_invitation_repository.dart';
import '../../domain/invitation.dart';

part 'invitations_provider.g.dart';

/// Kullanıcının bekleyen davetleri. Push/polling yok: shell'in üst çubuğu
/// (uygulama açılışı) ve Davetlerim ekranı (her girişte tazeler) izler;
/// autoDispose olduğu için çıkış yapınca bellekte kalmaz.
@riverpod
Future<List<Invitation>> myInvitations(Ref ref) => ref.watch(invitationRepositoryProvider).getMyInvitations();

/// Menüdeki "Davetlerim" rozeti ve üst çubuktaki menü noktası için. Liste
/// yüklenemezse 0 - rozet hata göstermez, hata Davetlerim ekranında görünür.
@riverpod
int pendingInvitationCount(Ref ref) => ref.watch(myInvitationsProvider).asData?.value.length ?? 0;

// keepAlive: ekran bunu sadece ref.read(...notifier) ile çağırıyor - istek
// sürerken dispose olup ref.invalidate hata fırlatmasın (bkz. PackageActions).
@Riverpod(keepAlive: true)
class InvitationActions extends _$InvitationActions {
  @override
  void build() {}

  /// Onaylanan görev/paket hemen görünsün diye /me de yenilenir (personel
  /// daveti Aktif Görev seçicisine düşer). Hata olsa bile (ör. 410 süresi
  /// dolmuş) liste tazelenir ki artık geçersiz davet ekranda kalmasın.
  Future<void> accept(Invitation invitation) async {
    try {
      await ref.read(invitationRepositoryProvider).accept(invitation);
      ref.invalidate(currentUserProvider);
    } finally {
      ref.invalidate(myInvitationsProvider);
    }
  }

  Future<void> reject(Invitation invitation) async {
    try {
      await ref.read(invitationRepositoryProvider).reject(invitation);
    } finally {
      ref.invalidate(myInvitationsProvider);
    }
  }
}
