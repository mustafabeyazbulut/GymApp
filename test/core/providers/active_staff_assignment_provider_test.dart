import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/active_staff_assignment_provider.dart';

class _FakeStore implements ActiveAssignmentStore {
  _FakeStore({this.stored, this.readCompleter, this.throwOnRead = false});

  int? stored;
  final Completer<void>? readCompleter;
  final bool throwOnRead;
  final writes = <int?>[];

  @override
  Future<int?> read() async {
    if (readCompleter != null) await readCompleter!.future;
    if (throwOnRead) throw Exception('depolama yok');
    return stored;
  }

  @override
  Future<void> write(int? assignmentId) async {
    writes.add(assignmentId);
    stored = assignmentId;
  }
}

ProviderContainer _container(_FakeStore store) {
  final container = ProviderContainer(overrides: [activeAssignmentStoreProvider.overrideWithValue(store)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('başlangıçta seçim yoktur', () {
    final container = _container(_FakeStore());
    expect(container.read(activeStaffAssignmentProvider), isNull);
  });

  test('kalıcı saklanan seçimi geri yükler', () async {
    final container = _container(_FakeStore(stored: 12));
    container.read(activeStaffAssignmentProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activeStaffAssignmentProvider), 12);
  });

  test('select seçimi değiştirir ve kalıcı saklar', () async {
    final store = _FakeStore();
    final container = _container(store);

    container.read(activeStaffAssignmentProvider.notifier).select(7);

    expect(container.read(activeStaffAssignmentProvider), 7);
    expect(store.writes, [7]);
  });

  test('reset seçimi temizler ve saklanan değeri siler', () async {
    final store = _FakeStore(stored: 7);
    final container = _container(store);
    container.read(activeStaffAssignmentProvider);
    await Future<void>.delayed(Duration.zero);

    container.read(activeStaffAssignmentProvider.notifier).reset();

    expect(container.read(activeStaffAssignmentProvider), isNull);
    expect(store.writes, [null]);
  });

  // Depolama okuması geç biterse, kullanıcının o arada yaptığı seçim eski
  // değerle ezilmemeli.
  test('geri yükleme, arada yapılan kullanıcı seçimini ezmez', () async {
    final readCompleter = Completer<void>();
    final container = _container(_FakeStore(stored: 3, readCompleter: readCompleter));
    container.read(activeStaffAssignmentProvider);

    container.read(activeStaffAssignmentProvider.notifier).select(9);
    readCompleter.complete();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activeStaffAssignmentProvider), 9);
  });

  test('depolama okunamazsa seçim boş kalır', () async {
    final container = _container(_FakeStore(throwOnRead: true));
    container.read(activeStaffAssignmentProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activeStaffAssignmentProvider), isNull);
  });
}
