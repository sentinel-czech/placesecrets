import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/contributor_profile.dart';
import '../../domain/models/poi.dart';
import 'providers/contributor_providers.dart';

/// Public contributor profile: avatar, handle, verified badge, bio, stats and
/// the places they authored. Reached from Hall of Fame and POI detail.
class ContributorProfileScreen extends ConsumerWidget {
  final String contributorId;
  const ContributorProfileScreen({required this.contributorId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = Localizations.localeOf(context).languageCode;
    final profileAsync = ref.watch(contributorProfileProvider(contributorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributor'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          debugPrint('Contributor load error: $err');
          return const Center(child: Text('Failed to load contributor'));
        },
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Contributor not found'));
          }
          return ListView(
            children: [
              _Header(profile: profile),
              const Divider(height: 1),
              _PoiList(contributorId: contributorId, langCode: langCode),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ContributorProfile profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.displayName,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: Colors.blue, size: 20),
              ],
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(profile.bio!,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
          if (_validWebsite(profile.websiteUrl) != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.link, size: 18),
              label: Text(profile.websiteUrl!),
              onPressed: () => _openWebsite(context, profile.websiteUrl!),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(value: '${profile.totalPois}', label: 'Places'),
              _Stat(
                value: profile.avgRating?.toStringAsFixed(1) ?? '–',
                label: 'Avg ★',
              ),
              _Stat(value: '${profile.totalRatings}', label: 'Ratings'),
            ],
          ),
        ],
      ),
    );
  }

  /// Only treat http(s) URLs as links (avoid rendering arbitrary schemes).
  static String? _validWebsite(String? url) {
    if (url == null) return null;
    final u = url.trim();
    return (u.startsWith('https://') || u.startsWith('http://')) ? u : null;
  }

  Future<void> _openWebsite(BuildContext context, String url) async {
    final valid = _validWebsite(url);
    if (valid == null) return;
    final uri = Uri.tryParse(valid);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: Colors.grey[600])),
      ],
    );
  }
}

class _PoiList extends ConsumerWidget {
  final String contributorId;
  final String langCode;
  const _PoiList({required this.contributorId, required this.langCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poisAsync = ref.watch(contributorPoisProvider(contributorId));
    return poisAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (pois) {
        if (pois.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No public places yet.',
                style: TextStyle(color: Colors.grey[600])),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Places',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ...pois.map((p) => _PoiTile(poi: p, langCode: langCode)),
          ],
        );
      },
    );
  }
}

class _PoiTile extends StatelessWidget {
  final Poi poi;
  final String langCode;
  const _PoiTile({required this.poi, required this.langCode});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.place_outlined),
      title: Text(poi.localizedName(langCode),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: poi.ratingBadge != null
          ? Text(poi.ratingBadge!,
              style: const TextStyle(
                  color: Color(0xFFB8960C), fontWeight: FontWeight.bold))
          : const Icon(Icons.chevron_right),
      onTap: () => context.push('/poi/${poi.id}'),
    );
  }
}
