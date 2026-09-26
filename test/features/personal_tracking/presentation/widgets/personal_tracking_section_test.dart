import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/personal_tracking/data/real_personal_log_repository.dart';
import 'package:gym_app/features/personal_tracking/domain/personal_log.dart';
import 'package:gym_app/features/personal_tracking/domain/personal_log_repository.dart';
import 'package:gym_app/features/personal_tracking/presentation/widgets/personal_tracking_section.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockPersonalLogRepository extends Mock implements PersonalLogRepository {}

final _l10n = lookupAppLocalizations(const Locale('tr'));

PersonalLog _measurement(int id, DateTime date, double weight) => PersonalLog(
      id: id,
      date: date,
      kind: PersonalLogKind.measurement,
      title: null,
      durationMinutes: null,
      notes: null,
      weightKg: weight,
      bodyFatPercent: null,
      waistCm: null,
      createdAt: DateTime.utc(2026, 9, 1),
    );

final _workout = PersonalLog(
  id: 10,
  date: DateTime(2026, 9, 25),
  kind: PersonalLogKind.workout,
  title: 'Sahil koşusu',
  durationMinutes: 40,
  notes: 'Tempolu',
  weightKg: null,
  bodyFatPercent: null,
  waistCm: null,
  createdAt: DateTime.utc(2026, 9, 25),
);

Future<_MockPersonalLogRepository> _pump(WidgetTester tester, List<PersonalLog> logs) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _MockPersonalLogRepository();
  var current = logs;
  when(() => repository.list(from: any(named: 'from'), to: any(named: 'to'))).thenAnswer((_) async => current);
  when(() => repository.delete(any())).thenAnswer((invocation) async {
    final id = invocation.positionalArguments.single as int;
    current = current.where((log) => log.id != id).toList();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [personalLogRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: PersonalTrackingSection()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('kayıt yoksa boş mesaj ve Kayıt ekle butonu', (tester) async {
    await _pump(tester, const []);

    expect(find.text(_l10n.personalLogEmptyMessage), findsOneWidget);
    expect(find.text(_l10n.personalLogAddButton), findsOneWidget);
    expect(find.text(_l10n.personalLogWeightTrendTitle), findsNothing);
  });

  testWidgets('antrenman kaydını başlık, süre ve notla listeler', (tester) async {
    await _pump(tester, [_workout]);

    expect(find.text('Sahil koşusu'), findsOneWidget);
    expect(find.text(_l10n.personalLogDurationValue(40)), findsOneWidget);
    expect(find.text('Tempolu'), findsOneWidget);
  });

  testWidgets('kilo gidişatını Türkçe ondalıkla ve öncekine göre farkla gösterir', (tester) async {
    await _pump(tester, [
      _measurement(1, DateTime(2026, 9, 20), 72.4),
      _measurement(2, DateTime(2026, 9, 10), 73),
    ]);

    expect(find.text(_l10n.personalLogWeightTrendTitle), findsOneWidget);
    expect(find.text('72,4 kg'), findsWidgets);
    expect(find.text('−0,6'), findsOneWidget);
  });

  testWidgets('silme onayından sonra kaydı siler', (tester) async {
    final repository = await _pump(tester, [_workout]);

    await tester.tap(find.byTooltip(_l10n.personalLogDeleteButton));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.personalLogDeleteConfirmTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, _l10n.personalLogDeleteButton));
    await tester.pumpAndSettle();

    verify(() => repository.delete(10)).called(1);
    expect(find.text('Sahil koşusu'), findsNothing);
    expect(find.text(_l10n.personalLogDeletedMessage), findsOneWidget);
  });

  testWidgets('Kayıt ekle formu açar', (tester) async {
    await _pump(tester, const []);

    await tester.tap(find.text(_l10n.personalLogAddButton));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.personalLogAddTitle), findsOneWidget);
  });
}
