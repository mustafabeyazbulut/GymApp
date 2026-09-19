// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_scheduling_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WeeklyClassSessions)
final weeklyClassSessionsProvider = WeeklyClassSessionsProvider._();

final class WeeklyClassSessionsProvider
    extends $AsyncNotifierProvider<WeeklyClassSessions, List<ClassSession>> {
  WeeklyClassSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyClassSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyClassSessionsHash();

  @$internal
  @override
  WeeklyClassSessions create() => WeeklyClassSessions();
}

String _$weeklyClassSessionsHash() =>
    r'bed6567953e255224b5a8ee1b60d474c66d539e3';

abstract class _$WeeklyClassSessions
    extends $AsyncNotifier<List<ClassSession>> {
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

@ProviderFor(MyClassEnrollments)
final myClassEnrollmentsProvider = MyClassEnrollmentsProvider._();

final class MyClassEnrollmentsProvider
    extends
        $AsyncNotifierProvider<MyClassEnrollments, List<MyClassEnrollment>> {
  MyClassEnrollmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myClassEnrollmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myClassEnrollmentsHash();

  @$internal
  @override
  MyClassEnrollments create() => MyClassEnrollments();
}

String _$myClassEnrollmentsHash() =>
    r'2f25de0b4e2bd63f6f6b458541e2a741912f49c4';

abstract class _$MyClassEnrollments
    extends $AsyncNotifier<List<MyClassEnrollment>> {
  FutureOr<List<MyClassEnrollment>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<MyClassEnrollment>>,
              List<MyClassEnrollment>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MyClassEnrollment>>,
                List<MyClassEnrollment>
              >,
              AsyncValue<List<MyClassEnrollment>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ClassSessionActions)
final classSessionActionsProvider = ClassSessionActionsProvider._();

final class ClassSessionActionsProvider
    extends $NotifierProvider<ClassSessionActions, void> {
  ClassSessionActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classSessionActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classSessionActionsHash();

  @$internal
  @override
  ClassSessionActions create() => ClassSessionActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$classSessionActionsHash() =>
    r'6b1441de962968b4c654114e263c7c01bd9d365b';

abstract class _$ClassSessionActions extends $Notifier<void> {
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
