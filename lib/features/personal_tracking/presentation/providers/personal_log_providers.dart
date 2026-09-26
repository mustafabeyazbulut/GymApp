import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/real_personal_log_repository.dart';
import '../../domain/personal_log.dart';

part 'personal_log_providers.g.dart';

// Kişisel takip listesi son bir yılı gösterir - kilo gidişatı ve geçmiş
// antrenmanlar için yeterli, sonsuz liste gerekmiyor.
const _historyDays = 365;

@riverpod
Future<List<PersonalLog>> personalLogs(Ref ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref
      .watch(personalLogRepositoryProvider)
      .list(from: today.subtract(const Duration(days: _historyDays)), to: today);
}

// keepAlive: sadece ref.read(...notifier) ile çağrılıyor - istek sürerken
// dispose olup ref.invalidate hata fırlatmasın (bkz. PackageActions).
@Riverpod(keepAlive: true)
class PersonalLogActions extends _$PersonalLogActions {
  @override
  void build() {}

  Future<void> save(PersonalLogDraft draft, {int? id}) async {
    final repository = ref.read(personalLogRepositoryProvider);
    if (id == null) {
      await repository.create(draft);
    } else {
      await repository.update(id, draft);
    }
    ref.invalidate(personalLogsProvider);
  }

  Future<void> delete(int id) async {
    await ref.read(personalLogRepositoryProvider).delete(id);
    ref.invalidate(personalLogsProvider);
  }
}
