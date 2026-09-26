// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_personal_log_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(personalLogRepository)
final personalLogRepositoryProvider = PersonalLogRepositoryProvider._();

final class PersonalLogRepositoryProvider
    extends
        $FunctionalProvider<
          PersonalLogRepository,
          PersonalLogRepository,
          PersonalLogRepository
        >
    with $Provider<PersonalLogRepository> {
  PersonalLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalLogRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalLogRepositoryHash();

  @$internal
  @override
  $ProviderElement<PersonalLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PersonalLogRepository create(Ref ref) {
    return personalLogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PersonalLogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PersonalLogRepository>(value),
    );
  }
}

String _$personalLogRepositoryHash() =>
    r'18f545e1f6f38a83f994e1574c27e59feec803cf';
