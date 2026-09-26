import 'invitation.dart';

abstract interface class InvitationRepository {
  /// Çağıranın kendi bekleyen, süresi dolmamış davetleri.
  Future<List<Invitation>> getMyInvitations();

  /// Uygulama içi onay - kullanıcı giriş yapmış ve telefonu doğrulanmış
  /// olduğu için kod istenmez (SMS kodu yolu ConfirmInvitationScreen'de).
  Future<void> accept(Invitation invitation);

  Future<void> reject(Invitation invitation);
}
