import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/audio_service.dart';
import '../../../domain/models/poi_audio_guide.dart';

part 'audio_providers.g.dart';

@Riverpod(keepAlive: true)
AudioGuideService audioGuideService(AudioGuideServiceRef ref) {
  final service = AudioGuideService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
}

@riverpod
class AudioPlayerState extends _$AudioPlayerState {
  @override
  AudioPlaybackState build() => const AudioPlaybackState();

  void setPlaying(String poiId) {
    state = AudioPlaybackState(
      poiId: poiId,
      status: PlaybackStatus.playing,
    );
  }

  void setPaused() {
    state = state.copyWith(status: PlaybackStatus.paused);
  }

  void setStopped() {
    state = const AudioPlaybackState();
  }
}

enum PlaybackStatus { idle, playing, paused }

class AudioPlaybackState {
  final String? poiId;
  final PlaybackStatus status;

  const AudioPlaybackState({
    this.poiId,
    this.status = PlaybackStatus.idle,
  });

  AudioPlaybackState copyWith({
    String? poiId,
    PlaybackStatus? status,
  }) =>
      AudioPlaybackState(
        poiId: poiId ?? this.poiId,
        status: status ?? this.status,
      );
}

@riverpod
Future<List<PoiAudioGuide>> poiAudioGuides(
  PoiAudioGuidesRef ref,
  String poiId,
) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('poi_audio_guides')
      .select()
      .eq('poi_id', poiId)
      .order('lang_code')
      .order('sort_order');

  return (response as List)
      .map((e) => PoiAudioGuide.fromJson(e as Map<String, dynamic>))
      .toList();
}
