// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hall_of_fame_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hallOfFameHash() => r'79809079f9bad8d1144a576c747b3609c7ae810d';

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

/// See also [hallOfFame].
@ProviderFor(hallOfFame)
const hallOfFameProvider = HallOfFameFamily();

/// See also [hallOfFame].
class HallOfFameFamily extends Family<AsyncValue<List<HallOfFameEntry>>> {
  /// See also [hallOfFame].
  const HallOfFameFamily();

  /// See also [hallOfFame].
  HallOfFameProvider call(
    String cityId,
  ) {
    return HallOfFameProvider(
      cityId,
    );
  }

  @override
  HallOfFameProvider getProviderOverride(
    covariant HallOfFameProvider provider,
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
  String? get name => r'hallOfFameProvider';
}

/// See also [hallOfFame].
class HallOfFameProvider
    extends AutoDisposeFutureProvider<List<HallOfFameEntry>> {
  /// See also [hallOfFame].
  HallOfFameProvider(
    String cityId,
  ) : this._internal(
          (ref) => hallOfFame(
            ref as HallOfFameRef,
            cityId,
          ),
          from: hallOfFameProvider,
          name: r'hallOfFameProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hallOfFameHash,
          dependencies: HallOfFameFamily._dependencies,
          allTransitiveDependencies:
              HallOfFameFamily._allTransitiveDependencies,
          cityId: cityId,
        );

  HallOfFameProvider._internal(
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
    FutureOr<List<HallOfFameEntry>> Function(HallOfFameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HallOfFameProvider._internal(
        (ref) => create(ref as HallOfFameRef),
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
  AutoDisposeFutureProviderElement<List<HallOfFameEntry>> createElement() {
    return _HallOfFameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HallOfFameProvider && other.cityId == cityId;
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
mixin HallOfFameRef on AutoDisposeFutureProviderRef<List<HallOfFameEntry>> {
  /// The parameter `cityId` of this provider.
  String get cityId;
}

class _HallOfFameProviderElement
    extends AutoDisposeFutureProviderElement<List<HallOfFameEntry>>
    with HallOfFameRef {
  _HallOfFameProviderElement(super.provider);

  @override
  String get cityId => (origin as HallOfFameProvider).cityId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
