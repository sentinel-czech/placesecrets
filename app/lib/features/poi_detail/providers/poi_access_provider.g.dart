// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi_access_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$poiAccessHash() => r'5ebef9b230e685f54e3333c7565d44eaec43eedc';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Returns the effective access level string for a POI (from server RPC)
///
/// Copied from [poiAccess].
@ProviderFor(poiAccess)
const poiAccessProvider = PoiAccessFamily();

/// Returns the effective access level string for a POI (from server RPC)
///
/// Copied from [poiAccess].
class PoiAccessFamily extends Family<AsyncValue<String>> {
  /// Returns the effective access level string for a POI (from server RPC)
  ///
  /// Copied from [poiAccess].
  const PoiAccessFamily();

  /// Returns the effective access level string for a POI (from server RPC)
  ///
  /// Copied from [poiAccess].
  PoiAccessProvider call(
    String poiId,
  ) {
    return PoiAccessProvider(
      poiId,
    );
  }

  @override
  PoiAccessProvider getProviderOverride(
    covariant PoiAccessProvider provider,
  ) {
    return call(
      provider.poiId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'poiAccessProvider';
}

/// Returns the effective access level string for a POI (from server RPC)
///
/// Copied from [poiAccess].
class PoiAccessProvider extends AutoDisposeFutureProvider<String> {
  /// Returns the effective access level string for a POI (from server RPC)
  ///
  /// Copied from [poiAccess].
  PoiAccessProvider(
    String poiId,
  ) : this._internal(
          (ref) => poiAccess(
            ref as PoiAccessRef,
            poiId,
          ),
          from: poiAccessProvider,
          name: r'poiAccessProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$poiAccessHash,
          dependencies: PoiAccessFamily._dependencies,
          allTransitiveDependencies: PoiAccessFamily._allTransitiveDependencies,
          poiId: poiId,
        );

  PoiAccessProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.poiId,
  }) : super.internal();

  final String poiId;

  @override
  Override overrideWith(
    FutureOr<String> Function(PoiAccessRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PoiAccessProvider._internal(
        (ref) => create(ref as PoiAccessRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        poiId: poiId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _PoiAccessProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PoiAccessProvider && other.poiId == poiId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, poiId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PoiAccessRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `poiId` of this provider.
  String get poiId;
}

class _PoiAccessProviderElement extends AutoDisposeFutureProviderElement<String>
    with PoiAccessRef {
  _PoiAccessProviderElement(super.provider);

  @override
  String get poiId => (origin as PoiAccessProvider).poiId;
}

String _$premiumContentHash() => r'59e7d7fea0308fed4a1e43f9088c12b13e9e2caa';

/// Fetches premium content for a POI
///
/// Copied from [premiumContent].
@ProviderFor(premiumContent)
const premiumContentProvider = PremiumContentFamily();

/// Fetches premium content for a POI
///
/// Copied from [premiumContent].
class PremiumContentFamily extends Family<AsyncValue<PoiPremiumContent?>> {
  /// Fetches premium content for a POI
  ///
  /// Copied from [premiumContent].
  const PremiumContentFamily();

  /// Fetches premium content for a POI
  ///
  /// Copied from [premiumContent].
  PremiumContentProvider call(
    String poiId,
  ) {
    return PremiumContentProvider(
      poiId,
    );
  }

  @override
  PremiumContentProvider getProviderOverride(
    covariant PremiumContentProvider provider,
  ) {
    return call(
      provider.poiId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'premiumContentProvider';
}

/// Fetches premium content for a POI
///
/// Copied from [premiumContent].
class PremiumContentProvider
    extends AutoDisposeFutureProvider<PoiPremiumContent?> {
  /// Fetches premium content for a POI
  ///
  /// Copied from [premiumContent].
  PremiumContentProvider(
    String poiId,
  ) : this._internal(
          (ref) => premiumContent(
            ref as PremiumContentRef,
            poiId,
          ),
          from: premiumContentProvider,
          name: r'premiumContentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$premiumContentHash,
          dependencies: PremiumContentFamily._dependencies,
          allTransitiveDependencies:
              PremiumContentFamily._allTransitiveDependencies,
          poiId: poiId,
        );

  PremiumContentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.poiId,
  }) : super.internal();

  final String poiId;

  @override
  Override overrideWith(
    FutureOr<PoiPremiumContent?> Function(PremiumContentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PremiumContentProvider._internal(
        (ref) => create(ref as PremiumContentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        poiId: poiId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PoiPremiumContent?> createElement() {
    return _PremiumContentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PremiumContentProvider && other.poiId == poiId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, poiId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PremiumContentRef on AutoDisposeFutureProviderRef<PoiPremiumContent?> {
  /// The parameter `poiId` of this provider.
  String get poiId;
}

class _PremiumContentProviderElement
    extends AutoDisposeFutureProviderElement<PoiPremiumContent?>
    with PremiumContentRef {
  _PremiumContentProviderElement(super.provider);

  @override
  String get poiId => (origin as PremiumContentProvider).poiId;
}

String _$purchasedPoiIdsHash() => r'9eb9a0b911a1e4f78b1a5ad9d8286fe5c42c731a';

/// Set of POI IDs the user has purchased individually
///
/// Copied from [purchasedPoiIds].
@ProviderFor(purchasedPoiIds)
final purchasedPoiIdsProvider = AutoDisposeFutureProvider<Set<String>>.internal(
  purchasedPoiIds,
  name: r'purchasedPoiIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$purchasedPoiIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PurchasedPoiIdsRef = AutoDisposeFutureProviderRef<Set<String>>;
String _$purchasedCityBundleIdsHash() =>
    r'c868db81c5e77622b47fd206004e0e03554d41ee';

/// Set of city IDs for which the user has a premium bundle
///
/// Copied from [purchasedCityBundleIds].
@ProviderFor(purchasedCityBundleIds)
final purchasedCityBundleIdsProvider =
    AutoDisposeFutureProvider<Set<String>>.internal(
  purchasedCityBundleIds,
  name: r'purchasedCityBundleIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$purchasedCityBundleIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PurchasedCityBundleIdsRef = AutoDisposeFutureProviderRef<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
