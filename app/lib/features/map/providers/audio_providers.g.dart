// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioGuideServiceHash() => r'7d9c4c35715f0cb854af46942e7b3384d14ce780';

/// See also [audioGuideService].
@ProviderFor(audioGuideService)
final audioGuideServiceProvider = Provider<AudioGuideService>.internal(
  audioGuideService,
  name: r'audioGuideServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioGuideServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioGuideServiceRef = ProviderRef<AudioGuideService>;
String _$poiAudioGuidesHash() => r'8e33a68ce2309c314820cd24bae5bf5164736cd1';

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

/// See also [poiAudioGuides].
@ProviderFor(poiAudioGuides)
const poiAudioGuidesProvider = PoiAudioGuidesFamily();

/// See also [poiAudioGuides].
class PoiAudioGuidesFamily extends Family<AsyncValue<List<PoiAudioGuide>>> {
  /// See also [poiAudioGuides].
  const PoiAudioGuidesFamily();

  /// See also [poiAudioGuides].
  PoiAudioGuidesProvider call(
    String poiId,
  ) {
    return PoiAudioGuidesProvider(
      poiId,
    );
  }

  @override
  PoiAudioGuidesProvider getProviderOverride(
    covariant PoiAudioGuidesProvider provider,
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
  String? get name => r'poiAudioGuidesProvider';
}

/// See also [poiAudioGuides].
class PoiAudioGuidesProvider
    extends AutoDisposeFutureProvider<List<PoiAudioGuide>> {
  /// See also [poiAudioGuides].
  PoiAudioGuidesProvider(
    String poiId,
  ) : this._internal(
          (ref) => poiAudioGuides(
            ref as PoiAudioGuidesRef,
            poiId,
          ),
          from: poiAudioGuidesProvider,
          name: r'poiAudioGuidesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$poiAudioGuidesHash,
          dependencies: PoiAudioGuidesFamily._dependencies,
          allTransitiveDependencies:
              PoiAudioGuidesFamily._allTransitiveDependencies,
          poiId: poiId,
        );

  PoiAudioGuidesProvider._internal(
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
    FutureOr<List<PoiAudioGuide>> Function(PoiAudioGuidesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PoiAudioGuidesProvider._internal(
        (ref) => create(ref as PoiAudioGuidesRef),
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
  AutoDisposeFutureProviderElement<List<PoiAudioGuide>> createElement() {
    return _PoiAudioGuidesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PoiAudioGuidesProvider && other.poiId == poiId;
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
mixin PoiAudioGuidesRef on AutoDisposeFutureProviderRef<List<PoiAudioGuide>> {
  /// The parameter `poiId` of this provider.
  String get poiId;
}

class _PoiAudioGuidesProviderElement
    extends AutoDisposeFutureProviderElement<List<PoiAudioGuide>>
    with PoiAudioGuidesRef {
  _PoiAudioGuidesProviderElement(super.provider);

  @override
  String get poiId => (origin as PoiAudioGuidesProvider).poiId;
}

String _$audioPlayerStateHash() => r'49bcbc57e8f0850fdc0b8b9e6c47cd90f9734e81';

/// See also [AudioPlayerState].
@ProviderFor(AudioPlayerState)
final audioPlayerStateProvider =
    AutoDisposeNotifierProvider<AudioPlayerState, AudioPlaybackState>.internal(
  AudioPlayerState.new,
  name: r'audioPlayerStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioPlayerStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AudioPlayerState = AutoDisposeNotifier<AudioPlaybackState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
