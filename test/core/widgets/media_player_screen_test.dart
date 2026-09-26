import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/core/widgets/media_player_screen.dart';
import 'package:gym_app/features/content_library/data/real_content_library_repository.dart';
import 'package:gym_app/features/content_library/domain/content_library_repository.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockContentLibraryRepository extends Mock implements ContentLibraryRepository {}

final _l10n = lookupAppLocalizations(const Locale('tr'));

Future<void> _pump(WidgetTester tester, ContentLibraryRepository repository, String contentType) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [contentLibraryRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaPlayerScreen(mediaFileId: 5, mediaContentType: contentType, title: 'Squat'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Backend paketi geçersiz üyeye medyayı 403 (ForbiddenViewMedia) ile
  // reddediyor - oynatıcı sonsuz yüklenmemeli, tek satır hata göstermeli.
  testWidgets('video: erişim 403 ise backend mesajını gösterir, oynatıcı başlatılmaz', (tester) async {
    final repository = _MockContentLibraryRepository();
    when(() => repository.ensureMediaAccessible(5)).thenThrow(
      const ApiException(statusCode: 403, errors: ['Bu medya dosyasını görüntüleme yetkiniz yok.']),
    );

    await _pump(tester, repository, 'video/mp4');

    expect(find.text('Bu medya dosyasını görüntüleme yetkiniz yok.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    verifyNever(() => repository.mediaAuthHeaders());
  });

  testWidgets('video: 403 gövdesiz gelirse yerelleştirilmiş yedek mesajı gösterir', (tester) async {
    final repository = _MockContentLibraryRepository();
    when(() => repository.ensureMediaAccessible(5)).thenThrow(const ApiException(statusCode: 403, errors: []));

    await _pump(tester, repository, 'video/mp4');

    expect(find.text(_l10n.mediaForbiddenMessage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('görsel: 403 gövdesiz gelirse yerelleştirilmiş yedek mesajı gösterir', (tester) async {
    final repository = _MockContentLibraryRepository();
    when(() => repository.downloadMediaBytes(5)).thenAnswer(
      (_) async => throw const ApiException(statusCode: 403, errors: []),
    );

    await _pump(tester, repository, 'image/jpeg');

    expect(find.text(_l10n.mediaForbiddenMessage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
