import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../data/repositories/poi_repository.dart';

class PoiBySlugScreen extends ConsumerStatefulWidget {
  final String countryCode;
  final String citySlug;
  final String poiSlug;

  const PoiBySlugScreen({
    super.key,
    required this.countryCode,
    required this.citySlug,
    required this.poiSlug,
  });

  @override
  ConsumerState<PoiBySlugScreen> createState() => _PoiBySlugScreenState();
}

class _PoiBySlugScreenState extends ConsumerState<PoiBySlugScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final repo = PoiRepository(
        Supabase.instance.client,
        ref.read(appDatabaseProvider),
      );
      final result =
          await repo.getPoiBySlug(widget.countryCode, widget.citySlug, widget.poiSlug);

      if (!mounted) return;

      if (result != null && result['poi_id'] != null) {
        context.go('/poi/${result['poi_id']}');
      } else {
        setState(() {
          _error = 'Place not found';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load place';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.place_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error ?? 'Place not found'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Map'),
            ),
          ],
        ),
      ),
    );
  }
}
