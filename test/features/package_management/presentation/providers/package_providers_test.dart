import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/package_management/data/real_package_repository.dart';
import 'package:gym_app/features/package_management/domain/package_assignment_summary.dart';
import 'package:gym_app/features/package_management/domain/package_repository.dart';
import 'package:gym_app/features/package_management/domain/package_summary.dart';
import 'package:gym_app/features/package_management/presentation/providers/package_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockPackageRepository extends Mock implements PackageRepository {}

void main() {
  late _MockPackageRepository repository;
  late ProviderContainer container;

  final package = PackageSummary(
    id: 1,
    companyId: 3,
    branchId: null,
    name: 'Aylık Üyelik',
    description: null,
    type: 'Duration',
    durationDays: 30,
    sessionCount: null,
    price: 1000,
    isActive: true,
  );

  final assignment = PackageAssignmentSummary(
    id: 1,
    packageId: 1,
    packageName: 'Aylık Üyelik',
    price: 1000,
    memberUserId: 7,
    memberFullName: 'Ayşe Yılmaz',
    memberPhone: '+905551112233',
    companyId: 3,
    branchId: 10,
    startDate: DateTime(2026, 1, 1),
    endDate: null,
    remainingSessions: null,
    status: 'Active',
    totalPaid: 400,
    remainingBalance: 600,
  );

  setUp(() {
    repository = _MockPackageRepository();
    container = ProviderContainer(overrides: [
      packageRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
  });

  test('packagesProvider loads from the repository', () async {
    when(() => repository.getPackages()).thenAnswer((_) async => [package]);

    final result = await container.read(packagesProvider.future);

    expect(result.single.name, 'Aylık Üyelik');
  });

  test('packageAssignmentsProvider forwards memberPhone to the repository', () async {
    when(() => repository.getPackageAssignments(memberPhone: '+905551112233'))
        .thenAnswer((_) async => [assignment]);

    final result =
        await container.read(packageAssignmentsProvider(memberPhone: '+905551112233').future);

    expect(result.single.memberFullName, 'Ayşe Yılmaz');
  });

  test('PackageActions.createPackage calls the repository then invalidates packagesProvider', () async {
    when(() => repository.getPackages()).thenAnswer((_) async => [package]);
    when(() => repository.createPackage(
          companyId: any(named: 'companyId'),
          branchId: any(named: 'branchId'),
          name: any(named: 'name'),
          description: any(named: 'description'),
          type: any(named: 'type'),
          durationDays: any(named: 'durationDays'),
          sessionCount: any(named: 'sessionCount'),
          price: any(named: 'price'),
        )).thenAnswer((_) async {});

    await container.read(packagesProvider.future);
    await container.read(packageActionsProvider.notifier).createPackage(
          companyId: 3,
          name: 'Aylık Üyelik',
          type: 'Duration',
          durationDays: 30,
          price: 1000,
        );
    await container.read(packagesProvider.future);

    verify(() => repository.createPackage(
          companyId: 3,
          branchId: null,
          name: 'Aylık Üyelik',
          description: null,
          type: 'Duration',
          durationDays: 30,
          sessionCount: null,
          price: 1000,
        )).called(1);
    verify(() => repository.getPackages()).called(2);
  });

  test('PackageActions.setPackageActive calls the repository then invalidates packagesProvider', () async {
    when(() => repository.getPackages()).thenAnswer((_) async => [package]);
    when(() => repository.setPackageActive(packageId: 1, isActive: false)).thenAnswer((_) async {});

    await container.read(packagesProvider.future);
    await container.read(packageActionsProvider.notifier).setPackageActive(packageId: 1, isActive: false);
    await container.read(packagesProvider.future);

    verify(() => repository.setPackageActive(packageId: 1, isActive: false)).called(1);
    verify(() => repository.getPackages()).called(2);
  });

  test('PackageActions.assignPackage calls the repository', () async {
    when(() => repository.assignPackage(packageId: 1, memberPhone: '+905551112233'))
        .thenAnswer((_) async {});

    await container
        .read(packageActionsProvider.notifier)
        .assignPackage(packageId: 1, memberPhone: '+905551112233');

    verify(() => repository.assignPackage(packageId: 1, memberPhone: '+905551112233')).called(1);
  });

  test('PackageActions.cancelPackageAssignment calls the repository then invalidates packageAssignmentsProvider',
      () async {
    when(() => repository.getPackageAssignments(memberPhone: null)).thenAnswer((_) async => [assignment]);
    when(() => repository.cancelPackageAssignment(1)).thenAnswer((_) async {});

    await container.read(packageAssignmentsProvider(memberPhone: null).future);
    await container.read(packageActionsProvider.notifier).cancelPackageAssignment(1);
    await container.read(packageAssignmentsProvider(memberPhone: null).future);

    verify(() => repository.cancelPackageAssignment(1)).called(1);
    verify(() => repository.getPackageAssignments(memberPhone: null)).called(2);
  });

  test('PackageActions.recordPayment calls the repository then invalidates packageAssignmentsProvider', () async {
    when(() => repository.getPackageAssignments(memberPhone: null)).thenAnswer((_) async => [assignment]);
    when(() => repository.recordPayment(
          packageAssignmentId: 1,
          amount: 400,
          method: 'Cash',
          note: null,
        )).thenAnswer((_) async {});

    await container.read(packageAssignmentsProvider(memberPhone: null).future);
    await container.read(packageActionsProvider.notifier).recordPayment(
          packageAssignmentId: 1,
          amount: 400,
          method: 'Cash',
        );
    // recordPayment sadece packageAssignmentsProvider'ı invalidate ediyor -
    // aktif bir dinleyici (widget) olmadan bu, arkaplanda kendiliğinden
    // yeniden çekmeyi tetiklemez; taze veri ancak provider tekrar
    // okunduğunda gelir (tıpkı gerçek bir ekranın ref.watch ile yapacağı
    // gibi).
    await container.read(packageAssignmentsProvider(memberPhone: null).future);

    verify(() => repository.recordPayment(packageAssignmentId: 1, amount: 400, method: 'Cash', note: null))
        .called(1);
    verify(() => repository.getPackageAssignments(memberPhone: null)).called(2);
  });
}
