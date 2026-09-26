// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_platform_report_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(platformReportRepository)
final platformReportRepositoryProvider = PlatformReportRepositoryProvider._();

final class PlatformReportRepositoryProvider
    extends
        $FunctionalProvider<
          PlatformReportRepository,
          PlatformReportRepository,
          PlatformReportRepository
        >
    with $Provider<PlatformReportRepository> {
  PlatformReportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformReportRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformReportRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlatformReportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlatformReportRepository create(Ref ref) {
    return platformReportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlatformReportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlatformReportRepository>(value),
    );
  }
}

String _$platformReportRepositoryHash() =>
    r'c261c80ea5995de28b8c8bebe056ced15254d1bc';
