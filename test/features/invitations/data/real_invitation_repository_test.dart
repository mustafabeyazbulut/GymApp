import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/invitations/data/real_invitation_repository.dart';
import 'package:gym_app/features/invitations/domain/invitation.dart';

const _json = {
  'content-type': ['application/json'],
};

Invitation _staffInvitation() => Invitation(
      id: 7,
      type: InvitationType.staff,
      companyName: 'Test Gym',
      branchName: 'Kadıköy',
      role: 'Trainer',
      packageName: null,
      invitedByName: 'Yönetici',
      createdAt: DateTime.utc(2026, 9, 26),
      expiresAt: DateTime.utc(2026, 9, 27),
    );

void main() {
  test('getMyInvitations GET /api/invitations/mine listesini tüm alanlarıyla ayrıştırır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _Adapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/api/invitations/mine');
      return ResponseBody.fromString(
        '[{"id":7,"type":"Staff","companyName":"Test Gym","branchName":"Kadıköy","role":"Trainer",'
        '"packageName":null,"invitedByName":"Yönetici","createdAt":"2026-09-26T10:00:00Z",'
        '"expiresAt":"2026-09-27T10:00:00Z"},'
        '{"id":8,"type":"Package","companyName":"Test Gym","branchName":"Beşiktaş","role":null,'
        '"packageName":"Aylık","invitedByName":null,"createdAt":"2026-09-26T11:00:00Z",'
        '"expiresAt":"2026-09-27T11:00:00Z"},'
        '{"id":9,"type":"GymAdmin","companyName":"Diğer Gym","branchName":null,"role":"GymAdmin",'
        '"packageName":null,"invitedByName":"Sistem Sahibi","createdAt":"2026-09-26T12:00:00Z",'
        '"expiresAt":"2026-09-27T12:00:00Z"}]',
        200,
        headers: _json,
      );
    });

    final invitations = await RealInvitationRepository(dio).getMyInvitations();

    expect(invitations, hasLength(3));
    final staff = invitations[0];
    expect(staff.id, 7);
    expect(staff.type, InvitationType.staff);
    expect(staff.companyName, 'Test Gym');
    expect(staff.branchName, 'Kadıköy');
    expect(staff.role, 'Trainer');
    expect(staff.packageName, isNull);
    expect(staff.invitedByName, 'Yönetici');
    expect(staff.createdAt, DateTime.utc(2026, 9, 26, 10));
    expect(staff.expiresAt, DateTime.utc(2026, 9, 27, 10));

    final package = invitations[1];
    expect(package.type, InvitationType.package);
    expect(package.role, isNull);
    expect(package.packageName, 'Aylık');
    expect(package.invitedByName, isNull);

    final gymAdmin = invitations[2];
    expect(gymAdmin.type, InvitationType.gymAdmin);
    expect(gymAdmin.branchName, isNull);
  });

  test('bilinmeyen davet türleri listeden atlanır (ileride eklenebilecek türlere dayanıklılık)', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _Adapter((_) => ResponseBody.fromString(
          '[{"id":1,"type":"Future","companyName":"X","branchName":null,"role":null,"packageName":null,'
          '"invitedByName":null,"createdAt":"2026-09-26T10:00:00Z","expiresAt":"2026-09-27T10:00:00Z"}]',
          200,
          headers: _json,
        ));

    expect(await RealInvitationRepository(dio).getMyInvitations(), isEmpty);
  });

  test('accept POST /api/invitations/{type}/{id}/accept çağırır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    RequestOptions? captured;
    dio.httpClientAdapter = _Adapter((options) {
      captured = options;
      return ResponseBody.fromString('', 204);
    });

    await RealInvitationRepository(dio).accept(_staffInvitation());

    expect(captured!.method, 'POST');
    expect(captured!.path, '/api/invitations/Staff/7/accept');
  });

  test('reject POST /api/invitations/{type}/{id}/reject çağırır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    RequestOptions? captured;
    dio.httpClientAdapter = _Adapter((options) {
      captured = options;
      return ResponseBody.fromString('', 204);
    });

    await RealInvitationRepository(dio).reject(_staffInvitation());

    expect(captured!.method, 'POST');
    expect(captured!.path, '/api/invitations/Staff/7/reject');
  });

  test('410 InvitationExpired backend mesajıyla ApiException olarak fırlatılır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _Adapter((_) => ResponseBody.fromString(
          '{"Status":410,"Errors":["Davetin süresi dolmuş."],"Code":"InvitationExpired"}',
          410,
          headers: _json,
        ));

    await expectLater(
      RealInvitationRepository(dio).accept(_staffInvitation()),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 410)
          .having((e) => e.errors, 'errors', ['Davetin süresi dolmuş.'])),
    );
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      _respond(options);
}
