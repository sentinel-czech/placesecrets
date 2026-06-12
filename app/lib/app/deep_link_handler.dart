import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/poi_detail/providers/poi_access_provider.dart';

/// Result of resolving a deep link URI.
sealed class DeepLinkResult {
  const DeepLinkResult();
}

class PurchaseSuccessResult extends DeepLinkResult {
  const PurchaseSuccessResult();
}

class PurchaseCancelResult extends DeepLinkResult {
  const PurchaseCancelResult();
}

class PlaceResult extends DeepLinkResult {
  final String countryCode;
  final String citySlug;
  final String poiSlug;
  const PlaceResult({required this.countryCode, required this.citySlug, required this.poiSlug});
}

class DeepLinkHandler {
  final GoRouter router;
  final WidgetRef ref;

  DeepLinkHandler({required this.router, required this.ref});

  /// Resolves a URI into a [DeepLinkResult] without side effects.
  /// Returns null if the URI doesn't match any known pattern.
  static DeepLinkResult? resolveUri(Uri uri) {
    final scheme = uri.scheme;
    final host = uri.host;
    final path = uri.path;
    final segments = uri.pathSegments;

    // placesecrets://purchase/success or https://.../purchase/success
    if (_matches(scheme, host, path, 'purchase/success') ||
        _matches(scheme, host, path, '/purchase/success')) {
      return const PurchaseSuccessResult();
    }

    // placesecrets://purchase/cancel or https://.../purchase/cancel
    if (_matches(scheme, host, path, 'purchase/cancel') ||
        _matches(scheme, host, path, '/purchase/cancel')) {
      return const PurchaseCancelResult();
    }

    // https://placesecrets.app/:countryCode/:citySlug/:poiSlug
    if (segments.length >= 3 &&
        segments[0] != 'purchase' &&
        segments[0].length == 2) {
      return PlaceResult(
        countryCode: segments[0],
        citySlug: segments[1],
        poiSlug: segments[2],
      );
    }

    return null;
  }

  /// Handles incoming deep links. Returns true if handled.
  bool handle(Uri uri) {
    final result = resolveUri(uri);
    if (result == null) return false;

    switch (result) {
      case PurchaseSuccessResult():
        _onPurchaseSuccess();
        return true;
      case PurchaseCancelResult():
        debugPrint('Purchase cancelled by user');
        return true;
      case PlaceResult(:final countryCode, :final citySlug, :final poiSlug):
        router.go('/$countryCode/$citySlug/$poiSlug');
        return true;
    }
  }

  void _onPurchaseSuccess() {
    ref.invalidate(purchasedPoiIdsProvider);
    ref.invalidate(purchasedCityBundleIdsProvider);
    router.go('/');
  }

  static bool _matches(String scheme, String host, String path, String expected) {
    if (scheme == 'placesecrets') {
      return '$host$path' == expected || path == expected;
    }
    return path == expected;
  }
}
