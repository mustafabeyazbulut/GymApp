// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the app should show the tab shell (true) or `/login` (false).
/// No persistence — resets to false every app launch, by design (see spec).

@ProviderFor(AuthState)
final authStateProvider = AuthStateProvider._();

/// Whether the app should show the tab shell (true) or `/login` (false).
/// No persistence — resets to false every app launch, by design (see spec).
final class AuthStateProvider extends $NotifierProvider<AuthState, bool> {
  /// Whether the app should show the tab shell (true) or `/login` (false).
  /// No persistence — resets to false every app launch, by design (see spec).
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  AuthState create() => AuthState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$authStateHash() => r'8ba5a9c513913682bf932e810d8dd570ebed4eb1';

/// Whether the app should show the tab shell (true) or `/login` (false).
/// No persistence — resets to false every app launch, by design (see spec).

abstract class _$AuthState extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
