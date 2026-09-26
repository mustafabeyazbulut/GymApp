import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/active_staff_assignment_provider.dart';
import '../../data/real_package_repository.dart';
import '../../domain/package_assignment_summary.dart';
import '../../domain/package_summary.dart';

part 'package_providers.g.dart';

// Listeler aktif göreve özel (backend X-Active-Assignment-Id'ye göre
// filtreliyor) - görev değişince yeniden yüklenmeleri için izleniyor.
@riverpod
Future<List<PackageSummary>> packages(Ref ref) {
  ref.watch(activeStaffAssignmentProvider);
  return ref.watch(packageRepositoryProvider).getPackages();
}

@riverpod
Future<List<PackageAssignmentSummary>> packageAssignments(Ref ref, {String? memberPhone}) {
  ref.watch(activeStaffAssignmentProvider);
  return ref.watch(packageRepositoryProvider).getPackageAssignments(memberPhone: memberPhone);
}

// Kendi state'i yok, sadece mutasyonları sunuyor - her biri başarı sonrası
// ilgili liste provider'larını invalidate ederek ekranların taze veriyle
// otomatik yenilenmesini sağlıyor.
//
// keepAlive: ekranlar bunu sadece ref.read(...notifier) ile çağırıyor; kimse
// dinlemediği için autoDispose iken istek sürerken dispose oluyor ve sonraki
// ref.invalidate "dispose edilmiş Ref" hatası fırlatıyordu - paket kaydı
// oluşsa da ekran kapanmıyor, başarı mesajı görünmüyordu.
@Riverpod(keepAlive: true)
class PackageActions extends _$PackageActions {
  @override
  void build() {}

  Future<void> createPackage({
    required int companyId,
    required int branchId,
    required String name,
    String? description,
    required String type,
    int? durationDays,
    int? sessionCount,
    required double price,
    int? maxFreezeDays,
  }) async {
    await ref.read(packageRepositoryProvider).createPackage(
          companyId: companyId,
          branchId: branchId,
          name: name,
          description: description,
          type: type,
          durationDays: durationDays,
          sessionCount: sessionCount,
          price: price,
          maxFreezeDays: maxFreezeDays,
        );
    ref.invalidate(packagesProvider);
  }

  Future<void> setPackageActive({required int packageId, required bool isActive}) async {
    await ref.read(packageRepositoryProvider).setPackageActive(packageId: packageId, isActive: isActive);
    ref.invalidate(packagesProvider);
  }

  Future<void> assignPackage({required int packageId, required String memberPhone}) async {
    await ref.read(packageRepositoryProvider).assignPackage(packageId: packageId, memberPhone: memberPhone);
    ref.invalidate(packageAssignmentsProvider);
  }

  Future<void> cancelPackageAssignment(int packageAssignmentId) async {
    await ref.read(packageRepositoryProvider).cancelPackageAssignment(packageAssignmentId);
    ref.invalidate(packageAssignmentsProvider);
  }

  Future<void> freezePackageAssignment(int packageAssignmentId) async {
    await ref.read(packageRepositoryProvider).freezePackageAssignment(packageAssignmentId);
    ref.invalidate(packageAssignmentsProvider);
  }

  Future<void> unfreezePackageAssignment(int packageAssignmentId) async {
    await ref.read(packageRepositoryProvider).unfreezePackageAssignment(packageAssignmentId);
    ref.invalidate(packageAssignmentsProvider);
  }

  Future<void> recordGeneralCheckIn(int packageAssignmentId) async {
    await ref.read(packageRepositoryProvider).recordGeneralCheckIn(packageAssignmentId);
    ref.invalidate(packageAssignmentsProvider);
  }

  Future<void> recordPayment({
    required int packageAssignmentId,
    required double amount,
    required String method,
    String? note,
  }) async {
    await ref.read(packageRepositoryProvider).recordPayment(
          packageAssignmentId: packageAssignmentId,
          amount: amount,
          method: method,
          note: note,
        );
    ref.invalidate(packageAssignmentsProvider);
  }
}
