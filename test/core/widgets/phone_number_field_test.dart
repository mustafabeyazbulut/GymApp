import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/widgets/phone_number_field.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';

final _l10n = lookupAppLocalizations(const Locale('tr'));

class _Harness {
  final formKey = GlobalKey<FormState>();
  String? value;
  String? submitted;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  bool allowEmail = false,
  bool isRequired = true,
}) async {
  final harness = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Form(
          key: harness.formKey,
          child: PhoneNumberField(
            labelText: 'Telefon',
            allowEmail: allowEmail,
            isRequired: isRequired,
            onChanged: (value) => harness.value = value,
            onSubmitted: (value) => harness.submitted = value,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  testWidgets('varsayılan ülke cihaz bölgesinden gelir', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('de', 'DE');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await _pump(tester);

    expect(find.text('+49'), findsOneWidget);
  });

  testWidgets('cihaz bölgesi yoksa varsayılan ülke Türkiye (+90)', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await _pump(tester);

    expect(find.text('+90'), findsOneWidget);
  });

  testWidgets('ulusal numarayı E.164 biçiminde bildirir', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final harness = await _pump(tester);

    await tester.enterText(find.byType(TextFormField), '5551234567');

    expect(harness.value, '+905551234567');
  });

  testWidgets('başa yazılan 0 tolere edilir', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final harness = await _pump(tester);

    await tester.enterText(find.byType(TextFormField), '05551234567');

    expect(harness.value, '+905551234567');
  });

  testWidgets('ülke seçiciden ülke değiştirilebilir', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final harness = await _pump(tester);

    await tester.tap(find.text('+90'));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.phoneCountryPickerTitle), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, _l10n.phoneCountrySearchHint), 'Almanya');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Almanya'));
    await tester.pumpAndSettle();

    expect(find.text('+49'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '15112345678');
    expect(harness.value, '+4915112345678');
  });

  testWidgets('+ ile yapıştırılan uluslararası numara ülkeyi değiştirir', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final harness = await _pump(tester);

    await tester.enterText(find.byType(TextFormField), '+4915112345678');
    await tester.pump();

    expect(harness.value, '+4915112345678');
    expect(find.text('+49'), findsOneWidget);
  });

  testWidgets('geçersiz numara doğrulamada hata gösterir ve değer bildirmez', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final harness = await _pump(tester);

    await tester.enterText(find.byType(TextFormField), '123');
    expect(harness.formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(harness.value, isNull);
    expect(find.text(_l10n.phoneInvalidError), findsOneWidget);
  });

  testWidgets('zorunlu alan boşsa zorunlu alan hatası gösterir', (tester) async {
    final harness = await _pump(tester);

    expect(harness.formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text(_l10n.commonFieldRequired), findsOneWidget);
  });

  testWidgets('zorunlu olmayan alan boşken geçerlidir', (tester) async {
    final harness = await _pump(tester, isRequired: false);

    expect(harness.formKey.currentState!.validate(), isTrue);
  });

  testWidgets('e-posta modunda e-posta yazılınca ülke seçici gizlenir ve metin olduğu gibi bildirilir', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final harness = await _pump(tester, allowEmail: true);

    await tester.enterText(find.byType(TextFormField), 'ayse@test.com');
    await tester.pump();

    expect(find.text('+90'), findsNothing);
    expect(harness.value, 'ayse@test.com');
    expect(harness.formKey.currentState!.validate(), isTrue);
  });

  testWidgets('e-posta modunda numara yazılınca yine E.164 bildirilir', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final harness = await _pump(tester, allowEmail: true);

    await tester.enterText(find.byType(TextFormField), '5551234567');
    await tester.pump();

    expect(find.text('+90'), findsOneWidget);
    expect(harness.value, '+905551234567');
  });

  testWidgets('klavyeden gönderildiğinde değeri onSubmitted ile bildirir', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final harness = await _pump(tester, isRequired: false);

    await tester.enterText(find.byType(TextFormField), '5551234567');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(harness.submitted, '+905551234567');
  });
}
