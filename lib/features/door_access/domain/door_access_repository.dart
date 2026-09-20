import 'zone.dart';

abstract interface class DoorAccessRepository {
  Future<List<Zone>> getZones(int branchId);
  Future<Zone> createZone({required int branchId, required String name});
  Future<void> deleteZone(int zoneId);

  Future<List<Door>> getDoors(int zoneId);
  Future<Door> createDoor({required int zoneId, required String name});
  Future<void> deleteDoor(int doorId);

  Future<List<ZoneAccessRule>> getZoneAccessRules(int zoneId);
  Future<ZoneAccessRule> createZoneAccessRule({required int zoneId, required String ruleType, String? ruleValue});
  Future<void> deleteZoneAccessRule(int ruleId);
}
