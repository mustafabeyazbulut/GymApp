// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_log_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(personalLogs)
final personalLogsProvider = PersonalLogsProvider._();

final class PersonalLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PersonalLog>>,
          List<PersonalLog>,
          FutureOr<List<PersonalLog>>
        >
    with
        $FutureModifier<List<PersonalLog>>,
        $FutureProvider<List<PersonalLog>> {
  PersonalLogsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalLogsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalLogsHash();

  @$internal
  @override
  $FutureProviderElement<List<PersonalLog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PersonalLog>> create(Ref ref) {
    return personalLogs(ref);
  }
}

String _$personalLogsHash() => r'd4c7dd0258c5f28b12b2dbb2672b6cdf27e2cf4c';

@ProviderFor(PersonalLogActions)
final personalLogActionsProvider = PersonalLogActionsProvider._();

final class PersonalLogActionsProvider
    extends $NotifierProvider<PersonalLogActions, void> {
  PersonalLogActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalLogActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalLogActionsHash();

  @$internal
  @override
  PersonalLogActions create() => PersonalLogActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$personalLogActionsHash() =>
    r'6685f7c0517d7b6bcf56c2a024e2f9d422bbca7c';

abstract class _$PersonalLogActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
