import 'personal_log.dart';

/// Kullanıcının kendi kişisel takip kayıtları - backend sadece çağıranın
/// kayıtlarını döndürür, başkasının kaydı 404'tür.
abstract interface class PersonalLogRepository {
  /// Yeniden eskiye sıralı.
  Future<List<PersonalLog>> list({required DateTime from, required DateTime to});

  Future<PersonalLog> create(PersonalLogDraft draft);

  Future<PersonalLog> update(int id, PersonalLogDraft draft);

  Future<void> delete(int id);
}
