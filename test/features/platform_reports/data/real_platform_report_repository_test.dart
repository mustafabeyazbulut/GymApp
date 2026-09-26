import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/platform_reports/data/real_platform_report_repository.dart';
import 'package:gym_app/features/platform_reports/domain/platform_report.dart';

const _json = {
  'content-type': ['application/json'],
};

const _summaryJson = '{"totalUsers":120,"newUsersInPeriod":14,'
    '"userGrowth":[{"date":"2026-09-24","newUsers":3},{"date":"2026-09-25","newUsers":0}],'
    '"companyCount":3,"activeCompanyCount":2,"branchCount":5,"activeMemberCount":48,"trainerCount":7,'
    '"staffCount":6,"packageSalesInPeriod":21,"revenueInPeriod":31500.5,"currency":"TRY",'
    '"companies":[{"companyId":1,"companyName":"Test Gym","isActive":true,"branchCount":2,'
    '"activeMemberCount":30,"trainerCount":4,"staffCount":3,"packageSalesInPeriod":15,"revenueInPeriod":22000}]}';

void main() {
  test('getSummary days parametresiyle çağırır ve tüm alanları ayrıştırır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    RequestOptions? captured;
    dio.httpClientAdapter = _Adapter((options) {
      captured = options;
      return ResponseBody.fromString(_summaryJson, 200, headers: _json);
    });

    final summary = await RealPlatformReportRepository(dio).getSummary(ReportPeriod.days30);

    expect(captured!.path, '/api/platform-reports/summary');
    expect(captured!.queryParameters, {'days': 30});
    expect(summary.totalUsers, 120);
    expect(summary.newUsersInPeriod, 14);
    expect(summary.userGrowth, hasLength(2));
    expect(summary.userGrowth.first.date, DateTime(2026, 9, 24));
    expect(summary.userGrowth.first.newUsers, 3);
    expect(summary.companyCount, 3);
    expect(summary.activeCompanyCount, 2);
    expect(summary.branchCount, 5);
    expect(summary.activeMemberCount, 48);
    expect(summary.trainerCount, 7);
    expect(summary.staffCount, 6);
    expect(summary.packageSalesInPeriod, 21);
    expect(summary.revenueInPeriod, 31500.5);
    expect(summary.currency, 'TRY');

    final company = summary.companies.single;
    expect(company.companyId, 1);
    expect(company.companyName, 'Test Gym');
    expect(company.isActive, isTrue);
    expect(company.metrics.branchCount, 2);
    expect(company.metrics.activeMemberCount, 30);
    expect(company.metrics.trainerCount, 4);
    expect(company.metrics.staffCount, 3);
    expect(company.metrics.packageSalesInPeriod, 15);
    // Tam sayı gelen gelir double'a çevrilir.
    expect(company.metrics.revenueInPeriod, 22000.0);
  });

  test('dönem değerleri sözleşmedeki gün sayılarına karşılık gelir', () {
    expect(ReportPeriod.values.map((p) => p.days), [7, 30, 90, 365]);
  });

  test('getCompanyBranches şube kırılımını ayrıştırır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    RequestOptions? captured;
    dio.httpClientAdapter = _Adapter((options) {
      captured = options;
      return ResponseBody.fromString(
        '[{"branchId":9,"branchName":"Kadıköy","isActive":true,"activeMemberCount":20,"trainerCount":3,'
        '"staffCount":1,"packageSalesInPeriod":10,"revenueInPeriod":15000.25}]',
        200,
        headers: _json,
      );
    });

    final branches = await RealPlatformReportRepository(dio).getCompanyBranches(1, ReportPeriod.days7);

    expect(captured!.path, '/api/platform-reports/companies/1/branches');
    expect(captured!.queryParameters, {'days': 7});
    final branch = branches.single;
    expect(branch.branchId, 9);
    expect(branch.branchName, 'Kadıköy');
    expect(branch.isActive, isTrue);
    expect(branch.metrics.activeMemberCount, 20);
    expect(branch.metrics.branchCount, isNull);
    expect(branch.metrics.revenueInPeriod, 15000.25);
  });

  test('403 ApiException olarak fırlatılır', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test'));
    dio.httpClientAdapter = _Adapter((_) => ResponseBody.fromString('', 403));

    await expectLater(
      RealPlatformReportRepository(dio).getSummary(ReportPeriod.days30),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
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
