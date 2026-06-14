import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/account/my_access_screen.dart';
import '../features/account/my_purchases_screen.dart';
import '../features/account/receipts_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/catalog/city_places_screen.dart';
import '../features/contributor/contributor_profile_screen.dart';
import '../features/export/export_screen.dart';
import '../features/hall_of_fame/hall_of_fame_screen.dart';
import '../features/history/history_screen.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/payment/paywall_screen.dart';
import '../features/poi_detail/poi_by_slug_screen.dart';
import '../features/poi_detail/poi_detail_screen.dart';
import '../features/purchase/purchase_poi_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shared/widgets/main_scaffold.dart';

part 'router.g.dart';

abstract class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isValidUuid(String? value) =>
      value != null && _uuidRegex.hasMatch(value);
}

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    navigatorKey: AppRouter.navigatorKey,
    initialLocation: '/',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('pref_onboarding_done') ?? false;
      if (!onboardingDone && state.fullPath != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'map',
            builder: (_, __) => const MapScreen(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (_, __) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/poi/:id',
        name: 'poi_detail',
        redirect: (_, state) {
          final id = state.pathParameters['id'];
          if (!AppRouter.isValidUuid(id)) return '/';
          return null;
        },
        builder: (_, state) =>
            PoiDetailScreen(poiId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/export',
        name: 'export',
        builder: (_, __) => const ExportScreen(),
      ),
      GoRoute(
        path: '/paywall/:cityId',
        name: 'paywall',
        redirect: (_, state) {
          final cityId = state.pathParameters['cityId'];
          if (!AppRouter.isValidUuid(cityId)) return '/';
          return null;
        },
        builder: (_, state) =>
            PaywallScreen(cityId: state.pathParameters['cityId']!),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/hall-of-fame/:cityId',
        name: 'hall_of_fame',
        redirect: (_, state) {
          final cityId = state.pathParameters['cityId'];
          if (!AppRouter.isValidUuid(cityId)) return '/';
          return null;
        },
        builder: (_, state) =>
            HallOfFameScreen(cityId: state.pathParameters['cityId']!),
      ),
      GoRoute(
        path: '/contributor/:id',
        name: 'contributor_profile',
        redirect: (_, state) {
          final id = state.pathParameters['id'];
          if (!AppRouter.isValidUuid(id)) return '/';
          return null;
        },
        builder: (_, state) => ContributorProfileScreen(
          contributorId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/:countryCode/:citySlug/:poiSlug',
        name: 'place_by_slug',
        builder: (_, state) => PoiBySlugScreen(
          countryCode: state.pathParameters['countryCode']!,
          citySlug: state.pathParameters['citySlug']!,
          poiSlug: state.pathParameters['poiSlug']!,
        ),
      ),
      GoRoute(
        path: '/purchase/poi/:poiId',
        name: 'purchase_poi',
        redirect: (_, state) {
          final poiId = state.pathParameters['poiId'];
          if (!AppRouter.isValidUuid(poiId)) return '/';
          return null;
        },
        builder: (_, state) =>
            PurchasePoiScreen(poiId: state.pathParameters['poiId']!),
      ),
      GoRoute(
        path: '/account/purchases',
        name: 'my_purchases',
        builder: (_, __) => const MyPurchasesScreen(),
      ),
      GoRoute(
        path: '/account/access',
        name: 'my_access',
        builder: (_, __) => const MyAccessScreen(),
      ),
      GoRoute(
        path: '/account/receipts',
        name: 'receipts',
        builder: (_, __) => const ReceiptsScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/catalog',
        name: 'catalog',
        builder: (_, __) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/catalog/:cityId',
        name: 'city_places',
        redirect: (_, state) {
          final cityId = state.pathParameters['cityId'];
          if (!AppRouter.isValidUuid(cityId)) return '/catalog';
          return null;
        },
        builder: (_, state) => CityPlacesScreen(
          cityId: state.pathParameters['cityId']!,
          cityName: state.extra is String ? state.extra as String : null,
        ),
      ),
    ],
  );
}
