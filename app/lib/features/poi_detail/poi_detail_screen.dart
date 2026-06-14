import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../data/repositories/poi_repository.dart';
import '../../domain/models/poi.dart';
import '../../domain/models/poi_premium_content.dart';
import 'widgets/audio_player_widget.dart';
import 'widgets/poi_reviews_section.dart';
import 'widgets/premium_poi_content.dart';
import 'widgets/rating_widget.dart';
import 'widgets/share_poi_button.dart';

class PoiDetailScreen extends ConsumerStatefulWidget {
  final String poiId;

  const PoiDetailScreen({super.key, required this.poiId});

  @override
  ConsumerState<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends ConsumerState<PoiDetailScreen> {
  late Timer _ratingTimer;
  bool _showRating = false;
  Poi? _poi;
  bool _loading = true;
  String _effectiveAccess = 'none';
  PoiPremiumContent? _premiumContent;

  @override
  void initState() {
    super.initState();
    _ratingTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _showRating = true);
    });
    _loadPoi();
  }

  Future<void> _loadPoi() async {
    // Try fetching from Supabase first (with city slug join)
    try {
      final response = await Supabase.instance.client
          .from('pois')
          .select('*, cities!inner(slug, name)')
          .eq('id', widget.poiId)
          .maybeSingle();

      if (response != null) {
        final poi = Poi.fromJson(response);
        setState(() {
          _poi = poi;
          _loading = false;
        });
        _loadAccess(poi);
        return;
      }
    } catch (_) {
      // Fall through to cache
    }

    // Offline fallback
    final cached = await ref.read(appDatabaseProvider).getAllCachedPois();
    final match = cached.where((c) => c.id == widget.poiId).firstOrNull;

    if (match != null) {
      setState(() {
        _poi = Poi(
          id: match.id,
          cityId: match.cityId,
          name: _parseJsonMap(match.nameJson),
          description: _parseJsonMap(match.descriptionJson),
          latitude: match.latitude,
          longitude: match.longitude,
          geofenceRadius: match.geofenceRadius,
          photoUrls: _parseJsonList(match.photoUrlsJson),
          audioUrls: _parseJsonMapNullable(match.audioUrlsJson),
          isPremium: match.isPremium,
          createdAt: match.cachedAt,
        );
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAccess(Poi poi) async {
    try {
      final repo = PoiRepository(
        Supabase.instance.client,
        ref.read(appDatabaseProvider),
      );
      final access = await repo.getPoiAccess(poi.id);
      if (!mounted) return;
      setState(() => _effectiveAccess = access);

      // Load premium content if user has access to a premium POI
      if (poi.accessLevelEnum == PoiAccessLevel.premiumPoi &&
          (access == 'full' || access == 'premium')) {
        final content = await repo.getPremiumContent(poi.id);
        if (mounted) setState(() => _premiumContent = content);
      }
    } catch (_) {
      // Silently fail — show basic content
    }
  }

  Map<String, String> _parseJsonMap(String json) {
    try {
      final decoded = Uri.decodeFull(json);
      return Map<String, String>.from(
          Map<String, dynamic>.from(_parseJson(decoded)));
    } catch (_) {
      return {};
    }
  }

  Map<String, String?> _parseJsonMapNullable(String json) {
    try {
      return Map<String, String?>.from(
          Map<String, dynamic>.from(_parseJson(json)));
    } catch (_) {
      return {};
    }
  }

  List<String> _parseJsonList(String json) {
    try {
      return List<String>.from(_parseJson(json) as List);
    } catch (_) {
      return [];
    }
  }

  dynamic _parseJson(String json) {
    return json;
  }

  @override
  void dispose() {
    _ratingTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_poi == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Point of interest not found')),
      );
    }

    final poi = _poi!;
    final langCode = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final accessLevel = poi.accessLevelEnum;

    return Scaffold(
      appBar: AppBar(
        title: Text(poi.localizedName(langCode)),
        actions: [
          SharePoiButton(poi: poi),
        ],
      ),
      body: ListView(
        children: [
          // Photo gallery
          if (poi.photoUrls.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: poi.photoUrls.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _openPhotoGallery(poi.photoUrls, index),
                  child: CachedNetworkImage(
                    imageUrl: poi.photoUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),
            ),

          // Perex — always shown
          if (poi.perex != null && poi.perex!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                poi.perex!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // Access level badge
          if (accessLevel == PoiAccessLevel.premiumPoi)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium,
                      size: 18, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Register CTA for public-only (anonymous users)
          if (accessLevel == PoiAccessLevel.public &&
              _effectiveAccess == 'none')
            _buildCtaCard(
              context,
              icon: Icons.person_add,
              title: 'Register to unlock more',
              subtitle: 'Create a free account to access additional places',
              onTap: () => context.push('/auth'),
            ),

          // Audio player (for registered+ access levels)
          if (_effectiveAccess != 'none') AudioPlayerWidget(poi: poi),

          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poi.localizedName(langCode),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),

                // Rating badge
                if (poi.ratingBadge != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.star,
                            color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${poi.avgRating?.toStringAsFixed(1)} (${poi.totalRatings} ratings)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                Text(
                  poi.localizedDescription(langCode),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),

          // Premium content section
          if (_premiumContent != null)
            PremiumPoiContent(content: _premiumContent!, poi: poi),

          // Upgrade card for premium POIs the user hasn't purchased
          if (accessLevel == PoiAccessLevel.premiumPoi &&
              _effectiveAccess != 'full' &&
              _effectiveAccess != 'premium')
            _buildCtaCard(
              context,
              icon: Icons.lock_open,
              title: 'Unlock Premium Content',
              subtitle: poi.premiumPrice != null
                  ? 'Get exclusive audio, photos & more for €${poi.premiumPrice!.toStringAsFixed(2)}'
                  : 'Get exclusive audio, photos & more',
              onTap: () => context.push('/purchase/poi/${poi.id}'),
              isPrimary: true,
            ),

          // Contributor badge — links to the public contributor profile.
          if (poi.contributorId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Community Contributed'),
                  subtitle: const Text('View contributor profile'),
                  trailing: const Icon(Icons.chevron_right),
                  dense: true,
                  onTap: () =>
                      context.push('/contributor/${poi.contributorId}'),
                ),
              ),
            ),

          // Rating widget — shown after 30s or audio completion
          if (_showRating)
            Padding(
              padding: const EdgeInsets.all(16),
              child: RatingWidget(
                poiId: widget.poiId,
                langCode: langCode,
              ),
            ),

          // Reviews list (read-only, always visible)
          PoiReviewsSection(poiId: widget.poiId),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCtaCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        color: isPrimary ? theme.colorScheme.primaryContainer : null,
        child: ListTile(
          leading: Icon(icon,
              color: isPrimary
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.primary),
          title: Text(title,
              style: isPrimary
                  ? TextStyle(color: theme.colorScheme.onPrimaryContainer)
                  : null),
          subtitle: Text(subtitle,
              style: isPrimary
                  ? TextStyle(
                      color: theme.colorScheme.onPrimaryContainer
                          .withAlpha(179))
                  : null),
          trailing: Icon(Icons.chevron_right,
              color: isPrimary
                  ? theme.colorScheme.onPrimaryContainer
                  : null),
          onTap: onTap,
        ),
      ),
    );
  }

  void _openPhotoGallery(List<String> urls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            itemCount: urls.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (context, index) => PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(urls[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
        ),
      ),
    );
  }
}
