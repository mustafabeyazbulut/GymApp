// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Uygulamanın tab shell'i mi (true) yoksa `/login`'i mi (false) göstereceği.
/// Başlangıçta bu, her zaman false'a sıfırlamak yerine saklanmış bir access
/// token olup olmadığını kontrol eder — gerçek oturumlar artık uygulama
/// başlatmaları arasında kalıcıdır.

@ProviderFor(AuthState)
final authStateProvider = AuthStateProvider._();

/// Uygulamanın tab shell'i mi (true) yoksa `/login`'i mi (false) göstereceği.
/// Başlangıçta bu, her zaman false'a sıfırlamak yerine saklanmış bir access
/// token olup olmadığını kontrol eder — gerçek oturumlar artık uygulama
/// başlatmaları arasında kalıcıdır.
final class AuthStateProvider extends $AsyncNotifierProvider<AuthState, bool> {
  /// Uygulamanın tab shell'i mi (true) yoksa `/login`'i mi (false) göstereceği.
  /// Başlangıçta bu, her zaman false'a sıfırlamak yerine saklanmış bir access
  /// token olup olmadığını kontrol eder — gerçek oturumlar artık uygulama
  /// başlatmaları arasında kalıcıdır.
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

String _$authStateHash() => r'a8431acd998878e4e248b1f9f3ca19a3af9c86f7';

/// Uygulamanın tab shell'i mi (true) yoksa `/login`'i mi (false) göstereceği.
/// Başlangıçta bu, her zaman false'a sıfırlamak yerine saklanmış bir access
/// token olup olmadığını kontrol eder — gerçek oturumlar artık uygulama
/// başlatmaları arasında kalıcıdır.

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
