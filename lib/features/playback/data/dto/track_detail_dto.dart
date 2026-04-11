// playback/data/dto/track_detail_dto.dart

// Project
import '../../domain/entities/track_details.dart';
import '../../domain/entities/waveform_data.dart';

/// Maps raw JSON from:
///   GET /api/v1/tracks/{trackId}
///   GET /api/v1/tracks/secret/{secretToken}
/// into a domain [TrackDetail] entity (without streamUrl — added later).
///
/// [streamUrl] is fetched separately from
/// GET /api/v1/player/tracks/{trackId}/source
/// and injected via [toEntity].
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

  /// Parses raw API JSON into a [TrackDetailDto].
  /// Returns null if required fields are missing.
  factory TrackDetailDto.fromJson(Map<String, dynamic> json) {
    return TrackDetailDto(
      // API returns 'trackId' for both endpoints
      trackId: (json['trackId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      // Regular endpoint: 'artist' is a plain string (artist display name)
      // Secret endpoint: same shape
      artist: (json['artist'] as String?) ?? '',
      artistId: (json['artistId'] as String?) ?? '',
      artistHandle: (json['artistHandle'] as String?) ?? '',
      artworkUrl: json['coverArtUrl'] as String?,
      // API returns durationMs as an int
      durationMs: json['durationMs'] as int?,
      likesCount: (json['likesCount'] as int?) ?? 0,
      repostsCount: (json['repostsCount'] as int?) ?? 0,
      waveformRaw: json['waveformData'] as List<dynamic>?,
    );
  }

  /// Converts this DTO into a domain [TrackDetail] entity.
  /// [streamUrl] is injected here after being fetched separately.
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
      // WaveformParser already exists from Sprint 3
      waveformData: waveformRaw != null
          ? WaveformData.fromRaw(waveformRaw!)
          : const WaveformData.empty(),
      likesCount: likesCount,
      repostsCount: repostsCount,
    );
  }
}