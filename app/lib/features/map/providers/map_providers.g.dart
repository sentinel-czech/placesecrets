// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeCitiesHash() => r'c34f34fe4b1e6e2b144ae83c14f8f0291af9bbc0';

/// See also [activeCities].
@ProviderFor(activeCities)
final activeCitiesProvider = AutoDisposeFutureProvider<List<City>>.internal(
  activeCities,
  name: r'activeCitiesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activeCitiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveCitiesRef = AutoDisposeFutureProviderRef<List<City>>;
String _$cityPoisHash() => r'c7129ebfaf83ddcf947b95a0a39369a5fd9844b2';

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

/// See also [cityPois].
@ProviderFor(cityPois)
const cityPoisProvider = CityPoisFamily();

/// See also [cityPois].
class CityPoisFamily extends Family<AsyncValue<List<Poi>>> {
  /// See also [cityPois].
  const CityPoisFamily();

  /// See also [cityPois].
  CityPoisProvider call(
    String cityId,
  ) {
    return CityPoisProvider(
      cityId,
    );
  }

  @override
  CityPoisProvider getProviderOverride(
    covariant CityPoisProvider provider,
  ) {
    return call(
      provider.cityId,
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
  String? get name => r'cityPoisProvider';
}

/// See also [cityPois].
class CityPoisProvider extends AutoDisposeFutureProvider<List<Poi>> {
  /// See also [cityPois].
  CityPoisProvider(
    String cityId,
  ) : this._internal(
          (ref) => cityPois(
            ref as CityPoisRef,
            cityId,
          ),
          from: cityPoisProvider,
          name: r'cityPoisProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$cityPoisHash,
          dependencies: CityPoisFamily._dependencies,
          allTransitiveDependencies: CityPoisFamily._allTransitiveDependencies,
          cityId: cityId,
        );

  CityPoisProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.cityId,
  }) : super.internal();

  final String cityId;

  @override
  Override overrideWith(
    FutureOr<List<Poi>> Function(CityPoisRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CityPoisProvider._internal(
        (ref) => create(ref as CityPoisRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        cityId: cityId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Poi>> createElement() {
    return _CityPoisProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CityPoisProvider && other.cityId == cityId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, cityId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CityPoisRef on AutoDisposeFutureProviderRef<List<Poi>> {
  /// The parameter `cityId` of this provider.
  String get cityId;
}

class _CityPoisProviderElement
    extends AutoDisposeFutureProviderElement<List<Poi>> with CityPoisRef {
  _CityPoisProviderElement(super.provider);

  @override
  String get cityId => (origin as CityPoisProvider).cityId;
}

String _$nearestCityHash() => r'ada184a5d8cd0374e3cf0e1240a9cabd80f6d114';

/// See also [nearestCity].
@ProviderFor(nearestCity)
final nearestCityProvider = AutoDisposeProvider<City?>.internal(
  nearestCity,
  name: r'nearestCityProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$nearestCityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NearestCityRef = AutoDisposeProviderRef<City?>;
String _$userLocationHash() => r'd85f5ff0076f17360051001868927f6640d6830d';

/// See also [UserLocation].
@ProviderFor(UserLocation)
final userLocationProvider =
    AutoDisposeNotifierProvider<UserLocation, AsyncValue<LatLng>>.internal(
  UserLocation.new,
  name: r'userLocationProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userLocationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserLocation = AutoDisposeNotifier<AsyncValue<LatLng>>;
String _$selectedCityHash() => r'ee7b332fbf3834e3e51e4d9e599b59491c1b820a';

/// See also [SelectedCity].
@ProviderFor(SelectedCity)
final selectedCityProvider =
    AutoDisposeNotifierProvider<SelectedCity, City?>.internal(
  SelectedCity.new,
  name: r'selectedCityProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedCityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedCity = AutoDisposeNotifier<City?>;
String _$selectedPoiHash() => r'14f32e2d4ed623592a435bb0d4670dc642e184b3';

/// See also [SelectedPoi].
@ProviderFor(SelectedPoi)
final selectedPoiProvider =
    AutoDisposeNotifierProvider<SelectedPoi, Poi?>.internal(
  SelectedPoi.new,
  name: r'selectedPoiProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedPoiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedPoi = AutoDisposeNotifier<Poi?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
