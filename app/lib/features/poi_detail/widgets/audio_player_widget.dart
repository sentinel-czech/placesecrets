import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../domain/models/poi.dart';
import '../../../domain/models/poi_audio_guide.dart';
import '../../map/providers/audio_providers.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  final Poi poi;

  const AudioPlayerWidget({super.key, required this.poi});

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  bool _expanded = false;
  PoiAudioGuide? _selectedGuide;

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final guidesAsync = ref.watch(poiAudioGuidesProvider(widget.poi.id));
    final hasDescription = widget.poi.localizedDescription(langCode).isNotEmpty;

    final service = ref.watch(audioGuideServiceProvider);
    final playerState = ref.watch(audioPlayerStateProvider);
    final isThisPoi = playerState.poiId == widget.poi.id;
    final isPlaying = isThisPoi && playerState.status == PlaybackStatus.playing;
    final theme = Theme.of(context);

    return guidesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _buildLegacyPlayer(
        context, service, playerState, langCode, hasDescription,
      ),
      data: (guides) {
        if (guides.isEmpty && !hasDescription) return const SizedBox.shrink();

        // Group guides by language
        final byLang = <String, List<PoiAudioGuide>>{};
        for (final g in guides) {
          byLang.putIfAbsent(g.langCode, () => []).add(g);
        }

        // If no guides at all, fall back to legacy (audio_urls or TTS)
        if (guides.isEmpty) {
          return _buildLegacyPlayer(
            context, service, playerState, langCode, hasDescription,
          );
        }

        // Auto-select first guide in user's language
        _selectedGuide ??= byLang[langCode]?.first ?? guides.first;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primaryContainer),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.headphones, color: theme.colorScheme.primary),
                title: Text(
                  'Audio Guides',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                subtitle: Text('${guides.length} guide${guides.length != 1 ? 's' : ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: () => _playGuide(service, _selectedGuide!, langCode),
                    ),
                    IconButton(
                      icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () => setState(() => _expanded = !_expanded),
                    ),
                  ],
                ),
              ),

              // Expanded guide list
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: guides.map((guide) {
                      final isSelected = _selectedGuide?.id == guide.id;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isSelected ? Icons.play_circle_filled : Icons.play_circle_outline,
                          color: isSelected ? theme.colorScheme.primary : null,
                          size: 20,
                        ),
                        title: Text(
                          guide.displayTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          guide.langCode.toUpperCase() +
                              (guide.formattedDuration != null ? ' · ${guide.formattedDuration}' : ''),
                          style: theme.textTheme.bodySmall,
                        ),
                        onTap: () {
                          setState(() => _selectedGuide = guide);
                          _playGuide(service, guide, langCode);
                        },
                      );
                    }).toList(),
                  ),
                ),

              // Progress bar
              if (_expanded && isThisPoi)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: StreamBuilder<Duration>(
                    stream: service.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = service.duration ?? Duration.zero;
                      final progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0;

                      return Column(
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position),
                                  style: theme.textTheme.bodySmall),
                              Text(_formatDuration(duration),
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegacyPlayer(
    BuildContext context,
    AudioGuideService service,
    AudioPlaybackState playerState,
    String langCode,
    bool hasDescription,
  ) {
    final audioUrl = widget.poi.audioUrlForLang(langCode);
    final hasAudio = audioUrl != null;

    if (!hasAudio && !hasDescription) return const SizedBox.shrink();

    final isThisPoi = playerState.poiId == widget.poi.id;
    final isPlaying = isThisPoi && playerState.status == PlaybackStatus.playing;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primaryContainer),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              hasAudio ? Icons.headphones : Icons.record_voice_over,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              hasAudio ? 'Audio Guide' : 'Text-to-Speech',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            subtitle: Text(
              hasAudio ? 'Listen to the audio guide' : 'Listen to the description',
            ),
            trailing: IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () => _toggleLegacyPlayback(service, langCode),
            ),
          ),
        ],
      ),
    );
  }

  void _playGuide(AudioGuideService service, PoiAudioGuide guide, String langCode) async {
    final playerState = ref.read(audioPlayerStateProvider);
    final isThisPoi = playerState.poiId == widget.poi.id;

    if (isThisPoi && playerState.status == PlaybackStatus.playing) {
      await service.pause();
      ref.read(audioPlayerStateProvider.notifier).setPaused();
    } else if (isThisPoi && playerState.status == PlaybackStatus.paused &&
        _selectedGuide?.id == guide.id) {
      await service.resume();
      ref.read(audioPlayerStateProvider.notifier).setPlaying(widget.poi.id);
    } else {
      await service.playGuide(
        audioUrl: guide.url,
        lang: guide.langCode,
      );
      ref.read(audioPlayerStateProvider.notifier).setPlaying(widget.poi.id);
      setState(() => _expanded = true);
    }
  }

  void _toggleLegacyPlayback(AudioGuideService service, String langCode) async {
    final playerState = ref.read(audioPlayerStateProvider);
    final isThisPoi = playerState.poiId == widget.poi.id;

    if (isThisPoi && playerState.status == PlaybackStatus.playing) {
      await service.pause();
      ref.read(audioPlayerStateProvider.notifier).setPaused();
    } else if (isThisPoi && playerState.status == PlaybackStatus.paused) {
      await service.resume();
      ref.read(audioPlayerStateProvider.notifier).setPlaying(widget.poi.id);
    } else {
      final audioUrl = widget.poi.audioUrlForLang(langCode);
      await service.playGuide(
        audioUrl: audioUrl,
        ttsText: audioUrl == null
            ? widget.poi.localizedDescription(langCode)
            : null,
        lang: langCode,
      );
      ref.read(audioPlayerStateProvider.notifier).setPlaying(widget.poi.id);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
