// playback/data/dto/track_detail_dto.dart

import '../../domain/entities/track_details.dart';
import '../../domain/entities/waveform_data.dart';

class TrackDetailDto {
  const TrackDetailDto({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.artistHandle,
    this.artworkUrl,
    this.durationMs,
    this.likesCount = 0,
    this.repostsCount = 0,
    this.waveformRaw,
  });

  final String trackId;
  final String title;
  final String artist;
  final String artistId;
  final String artistHandle;
  final String? artworkUrl;
  final int? durationMs;
  final int likesCount;
  final int repostsCount;
  final List<dynamic>? waveformRaw;

  factory TrackDetailDto.fromJson(Map<String, dynamic> json) {
    return TrackDetailDto(
      trackId: (json['trackId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      artist: (json['artist'] as String?) ?? '',
      artistId: (json['artistId'] as String?) ?? '',
      artistHandle: (json['artistHandle'] as String?) ?? '',
      artworkUrl: json['coverArtUrl'] as String?,
      durationMs: json['durationMs'] as int?,
      likesCount: (json['likesCount'] as int?) ?? 0,
      repostsCount: (json['repostsCount'] as int?) ?? 0,
      waveformRaw: json['waveformData'] as List<dynamic>?,
    );
  }

  TrackDetail toEntity({required String streamUrl}) {
    return TrackDetail(
      trackId: trackId,
      title: title,
      artist: artist,
      artistId: artistId,
      artistHandle: artistHandle,
      streamUrl: streamUrl,
      artworkUrl: artworkUrl,
      durationMs: durationMs,
      waveformData: waveformRaw != null && waveformRaw!.isNotEmpty
          ? WaveformData.fromRaw(waveformRaw!)
          : const WaveformData.empty(),
      likesCount: likesCount,
      repostsCount: repostsCount,
    );
  }
}
