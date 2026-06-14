// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contributor_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$contributorRepositoryHash() =>
    r'65e8441107ecc2a5d44dacdae33b99f74342b43d';

/// See also [contributorRepository].
@ProviderFor(contributorRepository)
final contributorRepositoryProvider =
    AutoDisposeProvider<ContributorRepository>.internal(
  contributorRepository,
  name: r'contributorRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$contributorRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ContributorRepositoryRef
    = AutoDisposeProviderRef<ContributorRepository>;
String _$contributorProfileHash() =>
    r'40edfbfbbc8a64680d585eb4217be1909bc2c986';

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

/// See also [contributorProfile].
@ProviderFor(contributorProfile)
const contributorProfileProvider = ContributorProfileFamily();

/// See also [contributorProfile].
class ContributorProfileFamily extends Family<AsyncValue<ContributorProfile?>> {
  /// See also [contributorProfile].
  const ContributorProfileFamily();

  /// See also [contributorProfile].
  ContributorProfileProvider call(
    String contributorId,
  ) {
    return ContributorProfileProvider(
      contributorId,
    );
  }

  @override
  ContributorProfileProvider getProviderOverride(
    covariant ContributorProfileProvider provider,
  ) {
    return call(
      provider.contributorId,
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
  String? get name => r'contributorProfileProvider';
}

/// See also [contributorProfile].
class ContributorProfileProvider
    extends AutoDisposeFutureProvider<ContributorProfile?> {
  /// See also [contributorProfile].
  ContributorProfileProvider(
    String contributorId,
  ) : this._internal(
          (ref) => contributorProfile(
            ref as ContributorProfileRef,
            contributorId,
          ),
          from: contributorProfileProvider,
          name: r'contributorProfileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$contributorProfileHash,
          dependencies: ContributorProfileFamily._dependencies,
          allTransitiveDependencies:
              ContributorProfileFamily._allTransitiveDependencies,
          contributorId: contributorId,
        );

  ContributorProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.contributorId,
  }) : super.internal();

  final String contributorId;

  @override
  Override overrideWith(
    FutureOr<ContributorProfile?> Function(ContributorProfileRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ContributorProfileProvider._internal(
        (ref) => create(ref as ContributorProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        contributorId: contributorId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ContributorProfile?> createElement() {
    return _ContributorProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ContributorProfileProvider &&
        other.contributorId == contributorId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, contributorId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ContributorProfileRef
    on AutoDisposeFutureProviderRef<ContributorProfile?> {
  /// The parameter `contributorId` of this provider.
  String get contributorId;
}

class _ContributorProfileProviderElement
    extends AutoDisposeFutureProviderElement<ContributorProfile?>
    with ContributorProfileRef {
  _ContributorProfileProviderElement(super.provider);

  @override
  String get contributorId =>
      (origin as ContributorProfileProvider).contributorId;
}

String _$contributorPoisHash() => r'660c2009e8890e2d88d7947a3ebb288cfed96bd0';

/// See also [contributorPois].
@ProviderFor(contributorPois)
const contributorPoisProvider = ContributorPoisFamily();

/// See also [contributorPois].
class ContributorPoisFamily extends Family<AsyncValue<List<Poi>>> {
  /// See also [contributorPois].
  const ContributorPoisFamily();

  /// See also [contributorPois].
  ContributorPoisProvider call(
    String contributorId,
  ) {
    return ContributorPoisProvider(
      contributorId,
    );
  }

  @override
  ContributorPoisProvider getProviderOverride(
    covariant ContributorPoisProvider provider,
  ) {
    return call(
      provider.contributorId,
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
  String? get name => r'contributorPoisProvider';
}

/// See also [contributorPois].
class ContributorPoisProvider extends AutoDisposeFutureProvider<List<Poi>> {
  /// See also [contributorPois].
  ContributorPoisProvider(
    String contributorId,
  ) : this._internal(
          (ref) => contributorPois(
            ref as ContributorPoisRef,
            contributorId,
          ),
          from: contributorPoisProvider,
          name: r'contributorPoisProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$contributorPoisHash,
          dependencies: ContributorPoisFamily._dependencies,
          allTransitiveDependencies:
              ContributorPoisFamily._allTransitiveDependencies,
          contributorId: contributorId,
        );

  ContributorPoisProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.contributorId,
  }) : super.internal();

  final String contributorId;

  @override
  Override overrideWith(
    FutureOr<List<Poi>> Function(ContributorPoisRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ContributorPoisProvider._internal(
        (ref) => create(ref as ContributorPoisRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        contributorId: contributorId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Poi>> createElement() {
    return _ContributorPoisProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ContributorPoisProvider &&
        other.contributorId == contributorId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, contributorId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ContributorPoisRef on AutoDisposeFutureProviderRef<List<Poi>> {
  /// The parameter `contributorId` of this provider.
  String get contributorId;
}

class _ContributorPoisProviderElement
    extends AutoDisposeFutureProviderElement<List<Poi>>
    with ContributorPoisRef {
  _ContributorPoisProviderElement(super.provider);

  @override
  String get contributorId => (origin as ContributorPoisProvider).contributorId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
