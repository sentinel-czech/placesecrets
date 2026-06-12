// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$visitRepositoryHash() => r'46505dac476584341a06c5bea102caa5ccb6c882';

/// See also [visitRepository].
@ProviderFor(visitRepository)
final visitRepositoryProvider = AutoDisposeProvider<VisitRepository>.internal(
  visitRepository,
  name: r'visitRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$visitRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VisitRepositoryRef = AutoDisposeProviderRef<VisitRepository>;
String _$visitHistoryHash() => r'd3b557a034d1a1f6fe3704875debc84fe2c76683';

/// See also [visitHistory].
@ProviderFor(visitHistory)
final visitHistoryProvider =
    AutoDisposeStreamProvider<List<VisitedPoi>>.internal(
  visitHistory,
  name: r'visitHistoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$visitHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VisitHistoryRef = AutoDisposeStreamProviderRef<List<VisitedPoi>>;
String _$travelStatsHash() => r'16a17f515e4b870c05f82b81899ea01f238ccb77';

/// See also [travelStats].
@ProviderFor(travelStats)
final travelStatsProvider = AutoDisposeFutureProvider<TravelStats>.internal(
  travelStats,
  name: r'travelStatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$travelStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TravelStatsRef = AutoDisposeFutureProviderRef<TravelStats>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
