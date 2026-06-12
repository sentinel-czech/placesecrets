import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/models/poi.dart';

class PurchasePoiScreen extends ConsumerStatefulWidget {
  final String poiId;

  const PurchasePoiScreen({super.key, required this.poiId});

  @override
  ConsumerState<PurchasePoiScreen> createState() => _PurchasePoiScreenState();
}

class _PurchasePoiScreenState extends ConsumerState<PurchasePoiScreen> {
  Poi? _poi;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPoi();
  }

  Future<void> _loadPoi() async {
    try {
      // Try to find the POI from cache
      final cached = await ref.read(appDatabaseProvider).getAllCachedPois();
      final match = cached.where((c) => c.id == widget.poiId).firstOrNull;
      if (match != null) {
        setState(() {
          _poi = Poi(
            id: match.id,
            cityId: match.cityId,
            name: {},
            description: {},
            latitude: match.latitude,
            longitude: match.longitude,
            isPremium: match.isPremium,
            createdAt: match.cachedAt,
          );
          _loading = false;
        });
      } else {
        // Fetch directly
        final response = await Supabase.instance.client
            .from('pois')
            .select('*, cities!inner(slug, name)')
            .eq('id', widget.poiId)
            .maybeSingle();
        if (response != null) {
          setState(() {
            _poi = Poi.fromJson(response);
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _purchasePoi() async {
    await _purchase(purchaseType: 'poi', poiId: widget.poiId);
  }

  Future<void> _purchaseBundle() async {
    if (_poi == null) return;
    await _purchase(purchaseType: 'area_premium', cityId: _poi!.cityId);
  }

  Future<void> _purchase({
    required String purchaseType,
    String? poiId,
    String? cityId,
  }) async {
    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
      final repo = PaymentRepository(Supabase.instance.client);
      final url = await repo.createPoiCheckout(
        purchaseType: purchaseType,
        poiId: poiId,
        cityId: cityId,
      );

      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        setState(() => _error = 'Could not open payment page');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_poi == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase')),
        body: const Center(child: Text('POI not found')),
      );
    }

    final poi = _poi!;
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Unlock Premium Content')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.workspace_premium,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              poi.localizedName(langCode),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (poi.perex != null) ...[
              const SizedBox(height: 8),
              Text(
                poi.perex!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),

            // Per-POI purchase
            if (poi.premiumPrice != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.place),
                  title: const Text('This place only'),
                  subtitle: Text('€${poi.premiumPrice!.toStringAsFixed(2)}'),
                  trailing: _purchasing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _purchasing ? null : _purchasePoi,
                ),
              ),

            const SizedBox(height: 12),

            // City premium bundle
            Card(
              color: theme.colorScheme.primaryContainer,
              child: ListTile(
                leading: Icon(Icons.location_city,
                    color: theme.colorScheme.onPrimaryContainer),
                title: Text('All premium places in city',
                    style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer)),
                subtitle: Text(
                  'Best value — unlock everything',
                  style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer
                          .withAlpha(179)),
                ),
                trailing: _purchasing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.chevron_right,
                        color: theme.colorScheme.onPrimaryContainer),
                onTap: _purchasing ? null : _purchaseBundle,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],

            const Spacer(),

            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Maybe later'),
            ),
          ],
        ),
      ),
    );
  }
}
