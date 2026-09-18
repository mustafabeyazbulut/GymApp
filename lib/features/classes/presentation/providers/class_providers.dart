import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/membership_context_provider.dart';
import '../../data/real_class_repository.dart';
import '../../domain/check_in.dart';
import '../../domain/reservation.dart';
import '../../domain/trainer.dart';

part 'class_providers.g.dart';

@riverpod
Future<List<Trainer>> classTrainers(Ref ref, int packageAssignmentId) =>
    ref.watch(classRepositoryProvider).getTrainers(packageAssignmentId);

@riverpod
Future<List<CheckIn>> classCheckIns(Ref ref, int packageAssignmentId) =>
    ref.watch(classRepositoryProvider).getCheckIns(packageAssignmentId);

// Şu an ekranda seçili PackageAssignment için rezervasyon listesi -
// "hangi üyeliği görüntülüyorum" bağlamı (bkz. core/providers/
// membership_context_provider.dart) burada da geçerli, Classes'ın kendi
// ayrı bir seçicisi yok, Membership ekranıyla aynı seçimi paylaşır.
@riverpod
class ClassReservations extends _$ClassReservations {
  @override
  Future<List<Reservation>> build() async {
    final memberships = await ref.watch(membershipsProvider.future);
    if (memberships.isEmpty) return [];
    final selectedId = ref.watch(selectedMembershipIdProvider);
    final id = memberships.any((m) => m.id == selectedId) ? selectedId! : memberships.first.id;
    return ref.watch(classRepositoryProvider).getReservations(id);
  }

  Future<void> createReservation({required int trainerId, required DateTime scheduledAt}) async {
    final id = await _currentPackageAssignmentId();
    if (id == null) return;
    final repository = ref.read(classRepositoryProvider);
    await repository.createReservation(packageAssignmentId: id, trainerId: trainerId, scheduledAt: scheduledAt);
    state = await AsyncValue.guard(() => repository.getReservations(id));
  }

  Future<void> cancelReservation(int reservationId) async {
    final id = await _currentPackageAssignmentId();
    if (id == null) return;
    final repository = ref.read(classRepositoryProvider);
    await repository.cancelReservation(reservationId);
    state = await AsyncValue.guard(() => repository.getReservations(id));
  }

  Future<int?> _currentPackageAssignmentId() async {
    final memberships = await ref.read(membershipsProvider.future);
    if (memberships.isEmpty) return null;
    final selectedId = ref.read(selectedMembershipIdProvider);
    return memberships.any((m) => m.id == selectedId) ? selectedId! : memberships.first.id;
  }
}
