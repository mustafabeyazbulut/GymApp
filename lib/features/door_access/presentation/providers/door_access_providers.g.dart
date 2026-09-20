// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'door_access_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ZonesNotifier)
final zonesProvider = ZonesNotifierFamily._();

final class ZonesNotifierProvider
    extends $AsyncNotifierProvider<ZonesNotifier, List<Zone>> {
  ZonesNotifierProvider._({
    required ZonesNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'zonesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$zonesNotifierHash();

  @override
  String toString() {
    return r'zonesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ZonesNotifier create() => ZonesNotifier();

  @override
  bool operator ==(Object other) {
    return other is ZonesNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$zonesNotifierHash() => r'8fbd063e6af00795565848421b923915aede681d';

final class ZonesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ZonesNotifier,
          AsyncValue<List<Zone>>,
          List<Zone>,
          FutureOr<List<Zone>>,
          int
        > {
  ZonesNotifierFamily._()
    : super(
        retry: null,
        name: r'zonesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ZonesNotifierProvider call(int branchId) =>
      ZonesNotifierProvider._(argument: branchId, from: this);

  @override
  String toString() => r'zonesProvider';
}

abstract class _$ZonesNotifier extends $AsyncNotifier<List<Zone>> {
  late final _$args = ref.$arg as int;
  int get branchId => _$args;

  FutureOr<List<Zone>> build(int branchId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Zone>>, List<Zone>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Zone>>, List<Zone>>,
              AsyncValue<List<Zone>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(DoorsNotifier)
final doorsProvider = DoorsNotifierFamily._();

final class DoorsNotifierProvider
    extends $AsyncNotifierProvider<DoorsNotifier, List<Door>> {
  DoorsNotifierProvider._({
    required DoorsNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'doorsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$doorsNotifierHash();

  @override
  String toString() {
    return r'doorsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DoorsNotifier create() => DoorsNotifier();

  @override
  bool operator ==(Object other) {
    return other is DoorsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$doorsNotifierHash() => r'2be73056eb9d6b506004aacad9ce217b9ae86fac';

final class DoorsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DoorsNotifier,
          AsyncValue<List<Door>>,
          List<Door>,
          FutureOr<List<Door>>,
          int
        > {
  DoorsNotifierFamily._()
    : super(
        retry: null,
        name: r'doorsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DoorsNotifierProvider call(int zoneId) =>
      DoorsNotifierProvider._(argument: zoneId, from: this);

  @override
  String toString() => r'doorsProvider';
}

abstract class _$DoorsNotifier extends $AsyncNotifier<List<Door>> {
  late final _$args = ref.$arg as int;
  int get zoneId => _$args;

  FutureOr<List<Door>> build(int zoneId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Door>>, List<Door>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Door>>, List<Door>>,
              AsyncValue<List<Door>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(ZoneAccessRulesNotifier)
final zoneAccessRulesProvider = ZoneAccessRulesNotifierFamily._();

final class ZoneAccessRulesNotifierProvider
    extends
        $AsyncNotifierProvider<ZoneAccessRulesNotifier, List<ZoneAccessRule>> {
  ZoneAccessRulesNotifierProvider._({
    required ZoneAccessRulesNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'zoneAccessRulesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$zoneAccessRulesNotifierHash();

  @override
  String toString() {
    return r'zoneAccessRulesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ZoneAccessRulesNotifier create() => ZoneAccessRulesNotifier();

  @override
  bool operator ==(Object other) {
    return other is ZoneAccessRulesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$zoneAccessRulesNotifierHash() =>
    r'd68ce70c33098e8cb888c92830e6f4d9c080bb25';

final class ZoneAccessRulesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ZoneAccessRulesNotifier,
          AsyncValue<List<ZoneAccessRule>>,
          List<ZoneAccessRule>,
          FutureOr<List<ZoneAccessRule>>,
          int
        > {
  ZoneAccessRulesNotifierFamily._()
    : super(
        retry: null,
        name: r'zoneAccessRulesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ZoneAccessRulesNotifierProvider call(int zoneId) =>
      ZoneAccessRulesNotifierProvider._(argument: zoneId, from: this);

  @override
  String toString() => r'zoneAccessRulesProvider';
}

abstract class _$ZoneAccessRulesNotifier
    extends $AsyncNotifier<List<ZoneAccessRule>> {
  late final _$args = ref.$arg as int;
  int get zoneId => _$args;

  FutureOr<List<ZoneAccessRule>> build(int zoneId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ZoneAccessRule>>, List<ZoneAccessRule>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ZoneAccessRule>>,
                List<ZoneAccessRule>
              >,
              AsyncValue<List<ZoneAccessRule>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
