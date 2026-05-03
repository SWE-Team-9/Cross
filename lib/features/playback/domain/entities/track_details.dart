import 'package:equatable/equatable.dart';

import '/core/models/track.dart';
import '../entities/waveform_data.dart';

class TrackDetail extends Equatable {
  const TrackDetail({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.artistHandle,
    required this.streamUrl,
    this.slug, 
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
  final String streamUrl;
  final String? slug; 
  final String? artworkUrl;
  final int? durationMs;
  final WaveformData waveformData;
  final int likesCount;
  final int repostsCount;

  Track toPlaybackTrack() {
    return Track(
      id: trackId,
      title: title,
      artist: artist,
      audioUrl: streamUrl,
      artworkUrl: artworkUrl,
      handle: artistHandle,
      slug: slug, 
      artistId: artistId,
      likesCount: likesCount,
      repostsCount: repostsCount,
      durationMs: durationMs,
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
        slug, 
        artworkUrl,
        durationMs,
        waveformData,
        likesCount,
        repostsCount,
      ];
}