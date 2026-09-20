import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/door_access_repository.dart';
import '../domain/zone.dart';

part 'real_door_access_repository.g.dart';

class RealDoorAccessRepository implements DoorAccessRepository {
  RealDoorAccessRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Zone>> getZones(int branchId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/zones', queryParameters: {'branchId': branchId});
      return response.data!.map((e) => Zone.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<Zone> createZone({required int branchId, required String name}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/api/zones', data: {'branchId': branchId, 'name': name});
      return Zone(id: response.data!['id'] as int, branchId: branchId, name: response.data!['name'] as String);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> deleteZone(int zoneId) async {
    try {
      await _dio.delete<void>('/api/zones/$zoneId');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<Door>> getDoors(int zoneId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/zones/$zoneId/doors');
      return response.data!.map((e) => Door.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<Door> createDoor({required int zoneId, required String name}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/api/zones/$zoneId/doors', data: {'name': name});
      return Door(id: response.data!['id'] as int, zoneId: zoneId, name: response.data!['name'] as String);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> deleteDoor(int doorId) async {
    try {
      await _dio.delete<void>('/api/zones/doors/$doorId');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<List<ZoneAccessRule>> getZoneAccessRules(int zoneId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/zones/$zoneId/access-rules');
      return response.data!.map((e) => ZoneAccessRule.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<ZoneAccessRule> createZoneAccessRule({required int zoneId, required String ruleType, String? ruleValue}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/zones/$zoneId/access-rules',
        data: {'ruleType': ruleType, 'ruleValue': ruleValue},
      );
      return ZoneAccessRule(id: response.data!['id'] as int, zoneId: zoneId, ruleType: ruleType, ruleValue: ruleValue);
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> deleteZoneAccessRule(int ruleId) async {
    try {
      await _dio.delete<void>('/api/zones/access-rules/$ruleId');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
DoorAccessRepository doorAccessRepository(Ref ref) => RealDoorAccessRepository(ref.watch(dioProvider));
