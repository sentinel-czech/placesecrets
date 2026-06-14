// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ratings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$canSubmitRatingHash() => r'109bb95aaf2789837a2a51ca5953ac8c0aa5a497';

/// Whether the current session may submit a rating: signed in with a real
/// (non-anonymous) account. The app keeps a persistent anonymous session, so
/// `currentUser != null` is not enough — anonymous users must be excluded.
///
/// Copied from [canSubmitRating].
@ProviderFor(canSubmitRating)
final canSubmitRatingProvider = AutoDisposeProvider<bool>.internal(
  canSubmitRating,
  name: r'canSubmitRatingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canSubmitRatingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanSubmitRatingRef = AutoDisposeProviderRef<bool>;
String _$myPoiRatingHash() => r'cc40af467586db704c3e6477d471ef23405f3133';

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

/// See also [myPoiRating].
@ProviderFor(myPoiRating)
const myPoiRatingProvider = MyPoiRatingFamily();

/// See also [myPoiRating].
class MyPoiRatingFamily extends Family<AsyncValue<PoiRating?>> {
  /// See also [myPoiRating].
  const MyPoiRatingFamily();

  /// See also [myPoiRating].
  MyPoiRatingProvider call(
    String poiId,
  ) {
    return MyPoiRatingProvider(
      poiId,
    );
  }

  @override
  MyPoiRatingProvider getProviderOverride(
    covariant MyPoiRatingProvider provider,
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
  String? get name => r'myPoiRatingProvider';
}

/// See also [myPoiRating].
class MyPoiRatingProvider extends AutoDisposeFutureProvider<PoiRating?> {
  /// See also [myPoiRating].
  MyPoiRatingProvider(
    String poiId,
  ) : this._internal(
          (ref) => myPoiRating(
            ref as MyPoiRatingRef,
            poiId,
          ),
          from: myPoiRatingProvider,
          name: r'myPoiRatingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$myPoiRatingHash,
          dependencies: MyPoiRatingFamily._dependencies,
          allTransitiveDependencies:
              MyPoiRatingFamily._allTransitiveDependencies,
          poiId: poiId,
        );

  MyPoiRatingProvider._internal(
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
    FutureOr<PoiRating?> Function(MyPoiRatingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MyPoiRatingProvider._internal(
        (ref) => create(ref as MyPoiRatingRef),
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
  AutoDisposeFutureProviderElement<PoiRating?> createElement() {
    return _MyPoiRatingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MyPoiRatingProvider && other.poiId == poiId;
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
mixin MyPoiRatingRef on AutoDisposeFutureProviderRef<PoiRating?> {
  /// The parameter `poiId` of this provider.
  String get poiId;
}

class _MyPoiRatingProviderElement
    extends AutoDisposeFutureProviderElement<PoiRating?> with MyPoiRatingRef {
  _MyPoiRatingProviderElement(super.provider);

  @override
  String get poiId => (origin as MyPoiRatingProvider).poiId;
}

String _$poiReviewsHash() => r'812ad49aa3af515aa13c46ce83659fe547a00f9e';

/// First page of reviews for a place. Additional pages are loaded by the
/// reviews widget directly via the repository; invalidate this to refresh.
///
/// Copied from [poiReviews].
@ProviderFor(poiReviews)
const poiReviewsProvider = PoiReviewsFamily();

/// First page of reviews for a place. Additional pages are loaded by the
/// reviews widget directly via the repository; invalidate this to refresh.
///
/// Copied from [poiReviews].
class PoiReviewsFamily extends Family<AsyncValue<List<PoiReview>>> {
  /// First page of reviews for a place. Additional pages are loaded by the
  /// reviews widget directly via the repository; invalidate this to refresh.
  ///
  /// Copied from [poiReviews].
  const PoiReviewsFamily();

  /// First page of reviews for a place. Additional pages are loaded by the
  /// reviews widget directly via the repository; invalidate this to refresh.
  ///
  /// Copied from [poiReviews].
  PoiReviewsProvider call(
    String poiId,
  ) {
    return PoiReviewsProvider(
      poiId,
    );
  }

  @override
  PoiReviewsProvider getProviderOverride(
    covariant PoiReviewsProvider provider,
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
  String? get name => r'poiReviewsProvider';
}

/// First page of reviews for a place. Additional pages are loaded by the
/// reviews widget directly via the repository; invalidate this to refresh.
///
/// Copied from [poiReviews].
class PoiReviewsProvider extends AutoDisposeFutureProvider<List<PoiReview>> {
  /// First page of reviews for a place. Additional pages are loaded by the
  /// reviews widget directly via the repository; invalidate this to refresh.
  ///
  /// Copied from [poiReviews].
  PoiReviewsProvider(
    String poiId,
  ) : this._internal(
          (ref) => poiReviews(
            ref as PoiReviewsRef,
            poiId,
          ),
          from: poiReviewsProvider,
          name: r'poiReviewsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$poiReviewsHash,
          dependencies: PoiReviewsFamily._dependencies,
          allTransitiveDependencies:
              PoiReviewsFamily._allTransitiveDependencies,
          poiId: poiId,
        );

  PoiReviewsProvider._internal(
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
    FutureOr<List<PoiReview>> Function(PoiReviewsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PoiReviewsProvider._internal(
        (ref) => create(ref as PoiReviewsRef),
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
  AutoDisposeFutureProviderElement<List<PoiReview>> createElement() {
    return _PoiReviewsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PoiReviewsProvider && other.poiId == poiId;
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
mixin PoiReviewsRef on AutoDisposeFutureProviderRef<List<PoiReview>> {
  /// The parameter `poiId` of this provider.
  String get poiId;
}

class _PoiReviewsProviderElement
    extends AutoDisposeFutureProviderElement<List<PoiReview>>
    with PoiReviewsRef {
  _PoiReviewsProviderElement(super.provider);

  @override
  String get poiId => (origin as PoiReviewsProvider).poiId;
}

String _$poiRatingStatsHash() => r'0bb1c4a629b1aee01a8d6abed08ce7d1711a3dfa';

/// See also [poiRatingStats].
@ProviderFor(poiRatingStats)
const poiRatingStatsProvider = PoiRatingStatsFamily();

/// See also [poiRatingStats].
class PoiRatingStatsFamily
    extends Family<AsyncValue<({double? avg, int count})>> {
  /// See also [poiRatingStats].
  const PoiRatingStatsFamily();

  /// See also [poiRatingStats].
  PoiRatingStatsProvider call(
    String poiId,
  ) {
    return PoiRatingStatsProvider(
      poiId,
    );
  }

  @override
  PoiRatingStatsProvider getProviderOverride(
    covariant PoiRatingStatsProvider provider,
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
  String? get name => r'poiRatingStatsProvider';
}

/// See also [poiRatingStats].
class PoiRatingStatsProvider
    extends AutoDisposeFutureProvider<({double? avg, int count})> {
  /// See also [poiRatingStats].
  PoiRatingStatsProvider(
    String poiId,
  ) : this._internal(
          (ref) => poiRatingStats(
            ref as PoiRatingStatsRef,
            poiId,
          ),
          from: poiRatingStatsProvider,
          name: r'poiRatingStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$poiRatingStatsHash,
          dependencies: PoiRatingStatsFamily._dependencies,
          allTransitiveDependencies:
              PoiRatingStatsFamily._allTransitiveDependencies,
          poiId: poiId,
        );

  PoiRatingStatsProvider._internal(
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
    FutureOr<({double? avg, int count})> Function(PoiRatingStatsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PoiRatingStatsProvider._internal(
        (ref) => create(ref as PoiRatingStatsRef),
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
  AutoDisposeFutureProviderElement<({double? avg, int count})> createElement() {
    return _PoiRatingStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PoiRatingStatsProvider && other.poiId == poiId;
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
mixin PoiRatingStatsRef
    on AutoDisposeFutureProviderRef<({double? avg, int count})> {
  /// The parameter `poiId` of this provider.
  String get poiId;
}

class _PoiRatingStatsProviderElement
    extends AutoDisposeFutureProviderElement<({double? avg, int count})>
    with PoiRatingStatsRef {
  _PoiRatingStatsProviderElement(super.provider);

  @override
  String get poiId => (origin as PoiRatingStatsProvider).poiId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
