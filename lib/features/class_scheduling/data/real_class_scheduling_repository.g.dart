// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_class_scheduling_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(classSchedulingRepository)
final classSchedulingRepositoryProvider = ClassSchedulingRepositoryProvider._();

final class ClassSchedulingRepositoryProvider
    extends
        $FunctionalProvider<
          ClassSchedulingRepository,
          ClassSchedulingRepository,
          ClassSchedulingRepository
        >
    with $Provider<ClassSchedulingRepository> {
  ClassSchedulingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classSchedulingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classSchedulingRepositoryHash();

  @$internal
  @override
  $ProviderElement<ClassSchedulingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClassSchedulingRepository create(Ref ref) {
    return classSchedulingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClassSchedulingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClassSchedulingRepository>(value),
    );
  }
}

String _$classSchedulingRepositoryHash() =>
    r'1e47f6a6aa977343ad317f10ca6c013491e925cd';
