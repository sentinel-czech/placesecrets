import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/poi_premium_content.dart';
import '../../../domain/models/poi.dart';

class PremiumPoiContent extends StatelessWidget {
  final PoiPremiumContent content;
  final Poi poi;

  const PremiumPoiContent({
    super.key,
    required this.content,
    required this.poi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium badge
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade700, Colors.amber.shade500],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'Premium Content',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Premium text content
        if (content.textContent != null && content.textContent!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              content.textContent!,
              style: theme.textTheme.bodyLarge,
            ),
          ),

        // Extra photos
        if (content.extraPhotos.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: content.extraPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: content.extraPhotos[index],
                  width: 280,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 280,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 280,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          ),
        ],

        // Related POIs
        if (content.relatedPoiIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Related Places',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          ...content.relatedPoiIds.map((relatedId) => ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text('Place $relatedId'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/poi/$relatedId'),
              )),
        ],
      ],
    );
  }
}
