import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/active_staff_assignment_provider.dart';
import '../../data/real_trainer_schedule_repository.dart';
import '../../domain/my_reservation.dart';

part 'my_reservations_provider.g.dart';

@riverpod
class MyReservations extends _$MyReservations {
  @override
  Future<List<MyReservation>> build() {
    // Antrenörün programı aktif göreve (şubeye) özel - görev değişince yenilenir.
    ref.watch(activeStaffAssignmentProvider);
    return ref.watch(trainerScheduleRepositoryProvider).getMyReservations();
  }

  Future<void> checkIn(int reservationId) => _mutate(() => ref.read(trainerScheduleRepositoryProvider).checkIn(reservationId));

  Future<void> markNoShow(int reservationId) =>
      _mutate(() => ref.read(trainerScheduleRepositoryProvider).markNoShow(reservationId));

  Future<void> cancel(int reservationId) => _mutate(() => ref.read(trainerScheduleRepositoryProvider).cancel(reservationId));

  Future<void> _mutate(Future<void> Function() action) async {
    final repository = ref.read(trainerScheduleRepositoryProvider);
    await action();
    state = await AsyncValue.guard(repository.getMyReservations);
  }
}
