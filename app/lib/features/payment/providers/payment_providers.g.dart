// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$paymentServiceHash() => r'43a27c9bd48b3da79637681f97b3a33983b74f45';

/// See also [paymentService].
@ProviderFor(paymentService)
final paymentServiceProvider = Provider<PaymentService>.internal(
  paymentService,
  name: r'paymentServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$paymentServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PaymentServiceRef = ProviderRef<PaymentService>;
String _$paymentConfigHash() => r'49fb88dc7dacac62a88c38f3756fd4777dcd40ca';

/// See also [paymentConfig].
@ProviderFor(paymentConfig)
final paymentConfigProvider =
    AutoDisposeFutureProvider<PaymentConfig?>.internal(
  paymentConfig,
  name: r'paymentConfigProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$paymentConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PaymentConfigRef = AutoDisposeFutureProviderRef<PaymentConfig?>;
String _$userPurchasesHash() => r'd51c89dea71c7c444da04ee21e625b135efd1fcd';

/// See also [userPurchases].
@ProviderFor(userPurchases)
final userPurchasesProvider =
    AutoDisposeFutureProvider<List<UserAccess>>.internal(
  userPurchases,
  name: r'userPurchasesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userPurchasesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserPurchasesRef = AutoDisposeFutureProviderRef<List<UserAccess>>;
String _$hasCityAccessHash() => r'738396cb35d0600c5934331b722399dd1f2552d3';

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

/// See also [hasCityAccess].
@ProviderFor(hasCityAccess)
const hasCityAccessProvider = HasCityAccessFamily();

/// See also [hasCityAccess].
class HasCityAccessFamily extends Family<AsyncValue<bool>> {
  /// See also [hasCityAccess].
  const HasCityAccessFamily();

  /// See also [hasCityAccess].
  HasCityAccessProvider call(
    String cityId,
  ) {
    return HasCityAccessProvider(
      cityId,
    );
  }

  @override
  HasCityAccessProvider getProviderOverride(
    covariant HasCityAccessProvider provider,
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
  String? get name => r'hasCityAccessProvider';
}

/// See also [hasCityAccess].
class HasCityAccessProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [hasCityAccess].
  HasCityAccessProvider(
    String cityId,
  ) : this._internal(
          (ref) => hasCityAccess(
            ref as HasCityAccessRef,
            cityId,
          ),
          from: hasCityAccessProvider,
          name: r'hasCityAccessProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hasCityAccessHash,
          dependencies: HasCityAccessFamily._dependencies,
          allTransitiveDependencies:
              HasCityAccessFamily._allTransitiveDependencies,
          cityId: cityId,
        );

  HasCityAccessProvider._internal(
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
    FutureOr<bool> Function(HasCityAccessRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasCityAccessProvider._internal(
        (ref) => create(ref as HasCityAccessRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _HasCityAccessProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasCityAccessProvider && other.cityId == cityId;
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
mixin HasCityAccessRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `cityId` of this provider.
  String get cityId;
}

class _HasCityAccessProviderElement
    extends AutoDisposeFutureProviderElement<bool> with HasCityAccessRef {
  _HasCityAccessProviderElement(super.provider);

  @override
  String get cityId => (origin as HasCityAccessProvider).cityId;
}

String _$paymentFlowStateHash() => r'2871f690fc7ad50162bb5f82a2c25f555042cbd1';

/// See also [PaymentFlowState].
@ProviderFor(PaymentFlowState)
final paymentFlowStateProvider =
    AutoDisposeNotifierProvider<PaymentFlowState, PaymentState>.internal(
  PaymentFlowState.new,
  name: r'paymentFlowStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$paymentFlowStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PaymentFlowState = AutoDisposeNotifier<PaymentState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
