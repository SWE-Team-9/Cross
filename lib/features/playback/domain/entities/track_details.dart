// playback/domain/entities/TrackDetail.dart

import 'package:equatable/equatable.dart';

import '/core/models/track.dart';
import '../entities/waveform_data.dart'; // already exists from Sprint 3

/// Full track detail as returned by the API.
///
/// Richer than [Track] (core/models/track.dart) which is the minimal
/// playback-only model. This entity carries everything the player UI
/// and deep link bridge need.
///
/// Convert to [Track] via [toPlaybackTrack] when handing off to PlayerCubit.
class TrackDetail extends Equatable {
  const TrackDetail({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.artistHandle,
    required this.streamUrl,
    this.artworkUrl,
    this.durationMs,
    this.waveformData = const WaveformData.empty(),
    this.likesCount = 0,
    this.repostsCount = 0,
  });

  final String trackId;
  final String title;
  final String artist;
  final String artistId;
  final String artistHandle;

  /// The CDN stream URL — fetched separately from
  /// GET /api/v1/player/tracks/{trackId}/source
  final String streamUrl;

  final String? artworkUrl;
  final int? durationMs;
  final WaveformData waveformData;
  final int likesCount;
  final int repostsCount;

  /// Converts this rich entity into the minimal [Track] model
  /// that [PlayerCubit.play()] expects.
  Track toPlaybackTrack() {
    return Track(
      id: trackId,
      title: title,
      artist: artist,
      audioUrl: streamUrl,
      artworkUrl: artworkUrl,
      handle: artistHandle,
    );
  }

  @override
  List<Object?> get props => [
        trackId,
        title,
        artist,
        artistId,
        artistHandle,
        streamUrl,
        artworkUrl,
        durationMs,
        waveformData,
        likesCount,
        repostsCount,
      ];
}
