// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entitlements_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$myEntitlementsHash() => r'8ccb5ab25e9d9575f331268924cb743fd7dc9948';

/// Calls the `get_my_entitlements()` RPC (migration 0448) returning the unified
/// "what do I own" payload: free quota, purchased POIs, cities, city bundles and
/// countries. Returns an empty map for anonymous/signed-out users.
///
/// Copied from [myEntitlements].
@ProviderFor(myEntitlements)
final myEntitlementsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  myEntitlements,
  name: r'myEntitlementsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myEntitlementsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyEntitlementsRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
