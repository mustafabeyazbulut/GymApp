// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fake_class_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(classRepository)
final classRepositoryProvider = ClassRepositoryProvider._();

final class ClassRepositoryProvider
    extends
        $FunctionalProvider<ClassRepository, ClassRepository, ClassRepository>
    with $Provider<ClassRepository> {
  ClassRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classRepositoryHash();

  @$internal
  @override
  $ProviderElement<ClassRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClassRepository create(Ref ref) {
    return classRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassRepository>(value),
    );
  }
}

String _$classRepositoryHash() => r'ea764e9ea4de0fa49892ecb945e5d014f2f02d3a';
