import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/poi.dart';
import '../map/providers/map_providers.dart';

/// Places within a single city. Reuses [cityPoisProvider] (offline-cached).
class CityPlacesScreen extends ConsumerWidget {
  final String cityId;
  final String? cityName;

  const CityPlacesScreen({required this.cityId, this.cityName, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = Localizations.localeOf(context).languageCode;
    final poisAsync = ref.watch(cityPoisProvider(cityId));

    return Scaffold(
      appBar: AppBar(title: Text(cityName ?? 'Places')),
      body: poisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          debugPrint('City places load error: $err');
          return const Center(child: Text('Failed to load places'));
        },
        data: (pois) {
          if (pois.isEmpty) {
            return const Center(child: Text('No places in this city yet.'));
          }
          return ListView.separated(
            itemCount: pois.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _PoiTile(poi: pois[i], langCode: langCode),
          );
        },
      ),
    );
  }
}

class _PoiTile extends StatelessWidget {
  final Poi poi;
  final String langCode;

  const _PoiTile({required this.poi, required this.langCode});

  @override
  Widget build(BuildContext context) {
    final thumb = poi.photoUrls.isNotEmpty ? poi.photoUrls.first : null;
    return ListTile(
      leading: SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: thumb != null
              ? Image.network(
                  thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(context),
                )
              : _placeholder(context),
        ),
      ),
      title: Text(
        poi.localizedName(langCode),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: poi.perex != null && poi.perex!.isNotEmpty
          ? Text(poi.perex!, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: poi.ratingBadge != null
          ? Text(
              poi.ratingBadge!,
              style: const TextStyle(
                color: Color(0xFFB8960C),
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      onTap: () => context.push('/poi/${poi.id}'),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(Icons.place, color: Colors.grey[500]),
      );
}
