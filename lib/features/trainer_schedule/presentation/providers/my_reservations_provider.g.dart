// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_reservations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MyReservations)
final myReservationsProvider = MyReservationsProvider._();

final class MyReservationsProvider
    extends $AsyncNotifierProvider<MyReservations, List<MyReservation>> {
  MyReservationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myReservationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myReservationsHash();

  @$internal
  @override
  MyReservations create() => MyReservations();
}

String _$myReservationsHash() => r'742e06db2fdcc7ac8ca944943ee4d95345a3ee89';

abstract class _$MyReservations extends $AsyncNotifier<List<MyReservation>> {
  FutureOr<List<MyReservation>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<MyReservation>>, List<MyReservation>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MyReservation>>, List<MyReservation>>,
              AsyncValue<List<MyReservation>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
