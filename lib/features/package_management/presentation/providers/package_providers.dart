import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/real_package_repository.dart';
import '../../domain/package_assignment_summary.dart';
import '../../domain/package_summary.dart';

part 'package_providers.g.dart';

@riverpod
Future<List<PackageSummary>> packages(Ref ref) => ref.watch(packageRepositoryProvider).getPackages();

@riverpod
Future<List<PackageAssignmentSummary>> packageAssignments(Ref ref, {String? memberPhone}) =>
    ref.watch(packageRepositoryProvider).getPackageAssignments(memberPhone: memberPhone);

// Kendi state'i yok, sadece mutasyonları sunuyor - her biri başarı sonrası
// ilgili liste provider'larını invalidate ederek ekranların taze veriyle
// otomatik yenilenmesini sağlıyor.
@riverpod
class PackageActions extends _$PackageActions {
  @override
  void build() {}

  Future<void> createPackage({
    required int companyId,
    int? branchId,
    required String name,
    String? description,
    required String type,
    int? durationDays,
    int? sessionCount,
    required double price,
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
        );
    ref.invalidate(packagesProvider);
  }

  Future<void> setPackageActive({required int packageId, required bool isActive}) async {
    await ref.read(packageRepositoryProvider).setPackageActive(packageId: packageId, isActive: isActive);
    ref.invalidate(packagesProvider);
  }

  Future<void> assignPackage({required int packageId, required String memberPhone}) async {
    await ref.read(packageRepositoryProvider).assignPackage(packageId: packageId, memberPhone: memberPhone);
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
