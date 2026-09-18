// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(classTrainers)
final classTrainersProvider = ClassTrainersFamily._();

final class ClassTrainersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Trainer>>,
          List<Trainer>,
          FutureOr<List<Trainer>>
        >
    with $FutureModifier<List<Trainer>>, $FutureProvider<List<Trainer>> {
  ClassTrainersProvider._({
    required ClassTrainersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'classTrainersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$classTrainersHash();

  @override
  String toString() {
    return r'classTrainersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Trainer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Trainer>> create(Ref ref) {
    final argument = this.argument as int;
    return classTrainers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassTrainersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$classTrainersHash() => r'ae613dad3bf23b2eb606b63256c79cf968dfcf25';

final class ClassTrainersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Trainer>>, int> {
  ClassTrainersFamily._()
    : super(
        retry: null,
        name: r'classTrainersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClassTrainersProvider call(int packageAssignmentId) =>
      ClassTrainersProvider._(argument: packageAssignmentId, from: this);

  @override
  String toString() => r'classTrainersProvider';
}

@ProviderFor(classCheckIns)
final classCheckInsProvider = ClassCheckInsFamily._();

final class ClassCheckInsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CheckIn>>,
          List<CheckIn>,
          FutureOr<List<CheckIn>>
        >
    with $FutureModifier<List<CheckIn>>, $FutureProvider<List<CheckIn>> {
  ClassCheckInsProvider._({
    required ClassCheckInsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'classCheckInsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$classCheckInsHash();

  @override
  String toString() {
    return r'classCheckInsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CheckIn>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CheckIn>> create(Ref ref) {
    final argument = this.argument as int;
    return classCheckIns(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassCheckInsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$classCheckInsHash() => r'6766a0ee4cac512a5fc35d0576d5a92c04505755';

final class ClassCheckInsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CheckIn>>, int> {
  ClassCheckInsFamily._()
    : super(
        retry: null,
        name: r'classCheckInsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClassCheckInsProvider call(int packageAssignmentId) =>
      ClassCheckInsProvider._(argument: packageAssignmentId, from: this);

  @override
  String toString() => r'classCheckInsProvider';
}

@ProviderFor(ClassReservations)
final classReservationsProvider = ClassReservationsProvider._();

final class ClassReservationsProvider
    extends $AsyncNotifierProvider<ClassReservations, List<Reservation>> {
  ClassReservationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classReservationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classReservationsHash();

  @$internal
  @override
  ClassReservations create() => ClassReservations();
}

String _$classReservationsHash() => r'a6c0b3cb4b01ebd70cfd170c36656766342307ad';

abstract class _$ClassReservations extends $AsyncNotifier<List<Reservation>> {
  FutureOr<List<Reservation>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<Reservation>>, List<Reservation>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Reservation>>, List<Reservation>>,
              AsyncValue<List<Reservation>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
