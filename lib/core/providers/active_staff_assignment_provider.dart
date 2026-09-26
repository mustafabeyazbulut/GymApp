import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_staff_assignment_provider.g.dart';

/// Kullanıcının menüdeki "Aktif Görev" seçimini (personel atamasının Id'si)
/// cihazda saklar; uygulama yeniden açıldığında aynı görevle devam edilir.
abstract interface class ActiveAssignmentStore {
  Future<int?> read();
  Future<void> write(int? assignmentId);
}

class SecureActiveAssignmentStore implements ActiveAssignmentStore {
  SecureActiveAssignmentStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'gym_app_active_assignment_id';

  @override
  Future<int?> read() async {
    final value = await _storage.read(key: _key);
    return value == null ? null : int.tryParse(value);
  }

  @override
  Future<void> write(int? assignmentId) => assignmentId == null
      ? _storage.delete(key: _key)
      : _storage.write(key: _key, value: assignmentId.toString());
}

@Riverpod(keepAlive: true)
ActiveAssignmentStore activeAssignmentStore(Ref ref) => SecureActiveAssignmentStore(const FlutterSecureStorage());

/// Personelin şu an hangi görevle (firma + şube + rol) hareket ettiği - değer
/// seçilen atamanın Id'sidir; null = kullanıcı seçim yapmadı.
///
/// Bu değer ham seçimdir: kullanıcının atamalarından biriyle eşleşmiyorsa
/// (atama kaldırıldı, cihazda başka kullanıcıdan kaldı) çözümleme
/// MeResult.activeStaffAssignment'ta varsayılan kurala döner. dioProvider
/// çözümlenen görevi her isteğe X-Active-Assignment-Id olarak ekler; backend
/// bu değere çağıranın kendi ataması olmadıkça güvenmez (403).
///
/// keepAlive: dioProvider'ın interceptor'ı bunu her istekte okuyor - dinleyen
/// ekran yokken dispose olsaydı seçim kaybolurdu (bkz. dio_client.dart'taki
/// keepAlive notu).
@Riverpod(keepAlive: true)
class ActiveStaffAssignment extends _$ActiveStaffAssignment {
  // Depolama okuması bitmeden kullanıcı seçim yaptıysa geri yükleme onu ezmesin.
  bool _changedSinceBuild = false;

  @override
  int? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    int? stored;
    try {
      stored = await ref.read(activeAssignmentStoreProvider).read();
    } catch (_) {
      // Depolama yoksa/okunamazsa varsayılan kurala göre devam edilir.
      return;
    }
    if (!_changedSinceBuild && stored != null) state = stored;
  }

  void select(int assignmentId) => _set(assignmentId);

  /// Seçimi temizler; çözümleme varsayılan kurala döner.
  void reset() => _set(null);

  void _set(int? assignmentId) {
    _changedSinceBuild = true;
    state = assignmentId;
    ref.read(activeAssignmentStoreProvider).write(assignmentId).catchError((Object _) {});
  }
}
