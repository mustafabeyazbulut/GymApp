import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/invitation.dart';
import '../domain/invitation_repository.dart';

part 'real_invitation_repository.g.dart';

class RealInvitationRepository implements InvitationRepository {
  RealInvitationRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Invitation>> getMyInvitations() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/invitations/mine');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(Invitation.tryFromJson)
          .whereType<Invitation>()
          .toList();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  @override
  Future<void> accept(Invitation invitation) => _post(invitation, 'accept');

  @override
  Future<void> reject(Invitation invitation) => _post(invitation, 'reject');

  Future<void> _post(Invitation invitation, String action) async {
    try {
      await _dio.post<void>('/api/invitations/${invitation.type.apiValue}/${invitation.id}/$action');
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }
}

@riverpod
InvitationRepository invitationRepository(Ref ref) => RealInvitationRepository(ref.watch(dioProvider));
