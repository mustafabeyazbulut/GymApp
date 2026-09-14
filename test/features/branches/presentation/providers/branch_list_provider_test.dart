import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/branches/data/branch_repository_impl.dart';
import 'package:gym_app/features/branches/domain/branch.dart';
import 'package:gym_app/features/branches/domain/branch_repository.dart';
import 'package:gym_app/features/branches/presentation/providers/branch_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockBranchRepository extends Mock implements BranchRepository {}

void main() {
  late _MockBranchRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockBranchRepository();
    container = ProviderContainer(
      overrides: [branchRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('build() loads the branch list from the repository', () async {
    when(() => repository.getBranches()).thenAnswer(
      (_) async => const [
        Branch(id: 1, companyId: 1, name: 'Merkez', address: 'Adres', isActive: true),
      ],
    );

    final result = await container.read(branchListProvider.future);

    expect(result, hasLength(1));
    expect(result.single.name, 'Merkez');
  });

  test('addBranch appends the newly created branch to state', () async {
    when(() => repository.getBranches()).thenAnswer(
      (_) async => const [
        Branch(id: 1, companyId: 1, name: 'Mevcut Şube', address: 'Eski Adres', isActive: true),
      ],
    );
    when(() => repository.createBranch(
          companyId: 1,
          name: 'Yeni Şube',
          address: 'Adres',
        )).thenAnswer(
      (_) async => const Branch(
        id: 5,
        companyId: 1,
        name: 'Yeni Şube',
        address: 'Adres',
        isActive: true,
      ),
    );

    await container.read(branchListProvider.future);
    await container.read(branchListProvider.notifier).addBranch(
          companyId: 1,
          name: 'Yeni Şube',
          address: 'Adres',
        );

    final state = container.read(branchListProvider).value;
    expect(state, hasLength(2));
    expect(state!.map((b) => b.name), containsAll(['Mevcut Şube', 'Yeni Şube']));
  });

  test('addBranch preserves previously loaded branches even if a refresh in between failed', () async {
    var getBranchesCallCount = 0;
    when(() => repository.getBranches()).thenAnswer((_) async {
      getBranchesCallCount++;
      if (getBranchesCallCount == 1) {
        return const [
          Branch(id: 1, companyId: 1, name: 'Mevcut Şube', address: 'Eski Adres', isActive: true),
        ];
      }
      throw Exception('network error');
    });
    when(() => repository.createBranch(
          companyId: 1,
          name: 'Yeni Şube',
          address: 'Adres',
        )).thenAnswer(
      (_) async => const Branch(
        id: 5,
        companyId: 1,
        name: 'Yeni Şube',
        address: 'Adres',
        isActive: true,
      ),
    );

    await container.read(branchListProvider.future);
    await container.read(branchListProvider.notifier).refresh();
    expect(container.read(branchListProvider).hasError, isTrue);

    await container.read(branchListProvider.notifier).addBranch(
          companyId: 1,
          name: 'Yeni Şube',
          address: 'Adres',
        );

    final state = container.read(branchListProvider).value;
    expect(state, hasLength(2));
    expect(state!.map((b) => b.name), containsAll(['Mevcut Şube', 'Yeni Şube']));
  });
}
