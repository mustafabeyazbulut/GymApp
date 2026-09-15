// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the app should show the tab shell (true) or `/login` (false).
/// On startup, this checks for a stored access token rather than always
/// resetting to false — real sessions now persist across app launches.

@ProviderFor(AuthState)
final authStateProvider = AuthStateProvider._();

/// Whether the app should show the tab shell (true) or `/login` (false).
/// On startup, this checks for a stored access token rather than always
/// resetting to false — real sessions now persist across app launches.
final class AuthStateProvider extends $AsyncNotifierProvider<AuthState, bool> {
  /// Whether the app should show the tab shell (true) or `/login` (false).
  /// On startup, this checks for a stored access token rather than always
  /// resetting to false — real sessions now persist across app launches.
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
}

String _$authStateHash() => r'e7bf16bd0975fe2a01e4bd96c4f2f7bcd45aa3b2';

/// Whether the app should show the tab shell (true) or `/login` (false).
/// On startup, this checks for a stored access token rather than always
/// resetting to false — real sessions now persist across app launches.

abstract class _$AuthState extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
