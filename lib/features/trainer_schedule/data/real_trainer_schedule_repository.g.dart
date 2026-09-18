// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_trainer_schedule_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(trainerScheduleRepository)
final trainerScheduleRepositoryProvider = TrainerScheduleRepositoryProvider._();

final class TrainerScheduleRepositoryProvider
    extends
        $FunctionalProvider<
          TrainerScheduleRepository,
          TrainerScheduleRepository,
          TrainerScheduleRepository
        >
    with $Provider<TrainerScheduleRepository> {
  TrainerScheduleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trainerScheduleRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trainerScheduleRepositoryHash();

  @$internal
  @override
  $ProviderElement<TrainerScheduleRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TrainerScheduleRepository create(Ref ref) {
    return trainerScheduleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrainerScheduleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrainerScheduleRepository>(value),
    );
  }
}

String _$trainerScheduleRepositoryHash() =>
    r'c3fbbc9f5e06ec78ad07da618b6e405d5c53de3d';
