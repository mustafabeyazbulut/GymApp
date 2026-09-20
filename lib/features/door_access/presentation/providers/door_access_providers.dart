import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/real_door_access_repository.dart';
import '../../domain/zone.dart';

part 'door_access_providers.g.dart';

@riverpod
class ZonesNotifier extends _$ZonesNotifier {
  @override
  Future<List<Zone>> build(int branchId) => ref.watch(doorAccessRepositoryProvider).getZones(branchId);

  Future<void> refresh() async {
    final repository = ref.read(doorAccessRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.getZones(branchId));
  }

  Future<void> create(String name) async {
    await ref.read(doorAccessRepositoryProvider).createZone(branchId: branchId, name: name);
    await refresh();
  }

  Future<void> delete(int zoneId) async {
    await ref.read(doorAccessRepositoryProvider).deleteZone(zoneId);
    await refresh();
  }
}

@riverpod
class DoorsNotifier extends _$DoorsNotifier {
  @override
  Future<List<Door>> build(int zoneId) => ref.watch(doorAccessRepositoryProvider).getDoors(zoneId);

  Future<void> refresh() async {
    final repository = ref.read(doorAccessRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.getDoors(zoneId));
  }

  Future<void> create(String name) async {
    await ref.read(doorAccessRepositoryProvider).createDoor(zoneId: zoneId, name: name);
    await refresh();
  }

  Future<void> delete(int doorId) async {
    await ref.read(doorAccessRepositoryProvider).deleteDoor(doorId);
    await refresh();
  }
}

@riverpod
class ZoneAccessRulesNotifier extends _$ZoneAccessRulesNotifier {
  @override
  Future<List<ZoneAccessRule>> build(int zoneId) => ref.watch(doorAccessRepositoryProvider).getZoneAccessRules(zoneId);

  Future<void> refresh() async {
    final repository = ref.read(doorAccessRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.getZoneAccessRules(zoneId));
  }

  Future<void> create({required String ruleType, String? ruleValue}) async {
    await ref.read(doorAccessRepositoryProvider).createZoneAccessRule(zoneId: zoneId, ruleType: ruleType, ruleValue: ruleValue);
    await refresh();
  }

  Future<void> delete(int ruleId) async {
    await ref.read(doorAccessRepositoryProvider).deleteZoneAccessRule(ruleId);
    await refresh();
  }
}
