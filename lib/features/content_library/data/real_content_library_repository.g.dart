// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_content_library_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(contentLibraryRepository)
final contentLibraryRepositoryProvider = ContentLibraryRepositoryProvider._();

final class ContentLibraryRepositoryProvider
    extends
        $FunctionalProvider<
          ContentLibraryRepository,
          ContentLibraryRepository,
          ContentLibraryRepository
        >
    with $Provider<ContentLibraryRepository> {
  ContentLibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentLibraryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentLibraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<ContentLibraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentLibraryRepository create(Ref ref) {
    return contentLibraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentLibraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentLibraryRepository>(value),
    );
  }
}

String _$contentLibraryRepositoryHash() =>
    r'37db53b1555510a2f8d7629563a085ea95eb996f';
