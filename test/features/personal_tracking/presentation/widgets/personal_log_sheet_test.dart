import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/personal_tracking/data/real_personal_log_repository.dart';
import 'package:gym_app/features/personal_tracking/domain/personal_log.dart';
import 'package:gym_app/features/personal_tracking/domain/personal_log_repository.dart';
import 'package:gym_app/features/personal_tracking/presentation/widgets/personal_log_sheet.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockPersonalLogRepository extends Mock implements PersonalLogRepository {}

final _dummyLog = PersonalLog(
  id: 1,
  date: DateTime(2026, 9, 25),
  kind: PersonalLogKind.workout,
  title: 'Koşu',
  durationMinutes: 30,
  notes: null,
  weightKg: null,
  bodyFatPercent: null,
  waistCm: null,
  createdAt: DateTime.utc(2026, 9, 25),
);

Future<_MockPersonalLogRepository> _openSheet(WidgetTester tester, {Locale locale = const Locale('tr'), PersonalLog? existing}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _MockPersonalLogRepository();
  when(() => repository.create(any())).thenAnswer((_) async => _dummyLog);
  when(() => repository.update(any(), any())).thenAnswer((_) async => _dummyLog);
  when(() => repository.list(from: any(named: 'from'), to: any(named: 'to'))).thenAnswer((_) async => const []);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [personalLogRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPersonalLogSheet(context, existing: existing),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('aç'));
  await tester.pumpAndSettle();
  return repository;
}

AppLocalizations _l10n([String code = 'tr']) => lookupAppLocalizations(Locale(code));

Future<void> _save(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.widgetWithText(ElevatedButton, l10n.personalLogSaveButton));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => registerFallbackValue(PersonalLogDraft(date: DateTime(2026), kind: PersonalLogKind.workout)));

  testWidgets('antrenman başlıksız kaydedilemez', (tester) async {
    final repository = await _openSheet(tester);

    await _save(tester, _l10n());

    expect(find.text(_l10n().personalLogTitleRequired), findsOneWidget);
    verifyNever(() => repository.create(any()));
  });

  testWidgets('antrenman başlık ve süreyle oluşturulur', (tester) async {
    final repository = await _openSheet(tester);
    await tester.enterText(find.widgetWithText(TextFormField, _l10n().personalLogTitleLabel), 'Koşu');
    await tester.enterText(find.widgetWithText(TextFormField, _l10n().personalLogDurationLabel), '45');

    await _save(tester, _l10n());

    final draft = verify(() => repository.create(captureAny())).captured.single as PersonalLogDraft;
    expect(draft.kind, PersonalLogKind.workout);
    expect(draft.title, 'Koşu');
    expect(draft.durationMinutes, 45);
    expect(draft.weightKg, isNull);
  });

  testWidgets('ölçüm en az bir değer olmadan kaydedilemez', (tester) async {
    final repository = await _openSheet(tester);
    await tester.tap(find.text(_l10n().personalLogKindMeasurement));
    await tester.pumpAndSettle();

    await _save(tester, _l10n());

    expect(find.text(_l10n().personalLogMeasurementRequired), findsOneWidget);
    verifyNever(() => repository.create(any()));
  });

  testWidgets('Türkçede virgüllü kilo değeri doğru ayrıştırılır', (tester) async {
    final repository = await _openSheet(tester);
    await tester.tap(find.text(_l10n().personalLogKindMeasurement));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, _l10n().personalLogWeightLabel), '72,4');

    await _save(tester, _l10n());

    final draft = verify(() => repository.create(captureAny())).captured.single as PersonalLogDraft;
    expect(draft.kind, PersonalLogKind.measurement);
    expect(draft.weightKg, 72.4);
    expect(draft.title, isNull);
  });

  testWidgets('İngilizcede virgüllü değer geçersiz sayılır', (tester) async {
    final l10n = _l10n('en');
    final repository = await _openSheet(tester, locale: const Locale('en'));
    await tester.tap(find.text(l10n.personalLogKindMeasurement));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, l10n.personalLogWeightLabel), '72,4');

    await _save(tester, l10n);

    expect(find.text(l10n.personalLogInvalidNumber), findsOneWidget);
    verifyNever(() => repository.create(any()));
  });

  testWidgets('var olan kayıt düzenlenince update çağrılır', (tester) async {
    final repository = await _openSheet(tester, existing: _dummyLog);
    expect(find.text(_l10n().personalLogEditTitle), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Koşu'), findsOneWidget);

    await _save(tester, _l10n());

    verify(() => repository.update(1, any())).called(1);
  });
}
