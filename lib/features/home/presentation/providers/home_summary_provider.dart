import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/membership_context_provider.dart';
import '../../../classes/domain/reservation.dart';
import '../../../classes/presentation/providers/class_providers.dart';
import '../../domain/home_summary.dart';

part 'home_summary_provider.g.dart';

// Ayrı bir HomeRepository yok - Home'un tüm içeriği zaten var olan
// membershipsProvider (seçili üyelik) ve Classes feature'ının trainer/
// reservation/check-in provider'larından türetiliyor, kendine ait bir ağ
// çağrısı yok.
@riverpod
Future<HomeSummary> homeSummary(Ref ref) async {
  final memberships = await ref.watch(membershipsProvider.future);
  if (memberships.isEmpty) {
    return const HomeSummary(
      companyName: '',
      packageName: '',
      endDate: null,
      nextReservation: null,
      weeklyAttendance: [],
    );
  }

  final selectedId = ref.watch(selectedMembershipIdProvider);
  final selected = memberships.any((m) => m.id == selectedId)
      ? memberships.firstWhere((m) => m.id == selectedId)
      : memberships.first;

  final trainers = await ref.watch(classTrainersProvider(selected.id).future);
  final reservations = await ref.watch(classReservationsProvider.future);
  final checkIns = await ref.watch(classCheckInsProvider(selected.id).future);

  final trainerNames = {for (final trainer in trainers) trainer.id: trainer.fullName};

  final now = DateTime.now();
  final upcoming = reservations
      .where((r) => r.status == ReservationStatus.booked && r.scheduledAt.isAfter(now))
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  final next = upcoming.isEmpty
      ? null
      : NextReservation(
          trainerName: trainerNames[upcoming.first.trainerId] ?? '—',
          scheduledAt: upcoming.first.scheduledAt,
        );

  final today = DateTime(now.year, now.month, now.day);
  final weeklyAttendance = List<(DateTime, bool)>.generate(7, (i) {
    final day = today.subtract(Duration(days: 6 - i));
    final attended = checkIns.any((checkIn) =>
        checkIn.checkedInAt.year == day.year &&
        checkIn.checkedInAt.month == day.month &&
        checkIn.checkedInAt.day == day.day);
    return (day, attended);
  });

  return HomeSummary(
    companyName: selected.companyName,
    packageName: selected.packageName,
    endDate: selected.endDate,
    nextReservation: next,
    weeklyAttendance: weeklyAttendance,
  );
}
