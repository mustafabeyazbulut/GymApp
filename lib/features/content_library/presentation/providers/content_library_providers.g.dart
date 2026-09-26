// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_library_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContentItemsNotifier)
final contentItemsProvider = ContentItemsNotifierProvider._();

final class ContentItemsNotifierProvider
    extends $AsyncNotifierProvider<ContentItemsNotifier, List<ContentItem>> {
  ContentItemsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentItemsNotifierHash();

  @$internal
  @override
  ContentItemsNotifier create() => ContentItemsNotifier();
}

String _$contentItemsNotifierHash() =>
    r'28909f622bafe50be6692e115252b44dd7df3fe1';

abstract class _$ContentItemsNotifier
    extends $AsyncNotifier<List<ContentItem>> {
  FutureOr<List<ContentItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ContentItem>>, List<ContentItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ContentItem>>, List<ContentItem>>,
              AsyncValue<List<ContentItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
