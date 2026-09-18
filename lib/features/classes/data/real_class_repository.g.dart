// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_class_repository.dart';

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

String _$classRepositoryHash() => r'1a1e92501fbf97d8e7e0b22d861286cfede7c8fe';
