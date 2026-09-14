// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClassList)
final classListProvider = ClassListProvider._();

final class ClassListProvider
    extends $AsyncNotifierProvider<ClassList, List<ClassSession>> {
  ClassListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classListHash();

  @$internal
  @override
  ClassList create() => ClassList();
}

String _$classListHash() => r'fff6a1800ab98aa123ddeb21fc04808a1fae48c3';

abstract class _$ClassList extends $AsyncNotifier<List<ClassSession>> {
  FutureOr<List<ClassSession>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ClassSession>>, List<ClassSession>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ClassSession>>, List<ClassSession>>,
              AsyncValue<List<ClassSession>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
