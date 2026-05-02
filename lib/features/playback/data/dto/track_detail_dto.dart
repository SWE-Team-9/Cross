// playback/data/dto/track_detail_dto.dart
//
// ✅ Fix: API returns "id" at root level, not "trackId".
//         Falls back to "trackId" for safety.

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
    // ✅ API returns "id" — fallback to "trackId" just in case
    final trackId =
        (json['id'] as String?)?.trim().isNotEmpty == true
            ? (json['id'] as String).trim()
            : (json['trackId'] as String?)?.trim() ?? '';

    // Artist: flat field OR nested uploader.profile
    final uploader = json['uploader'] as Map<String, dynamic>?;
    final profile = uploader?['profile'] as Map<String, dynamic>?;

    final artist = (json['artist'] as String?)?.trim().isNotEmpty == true
        ? (json['artist'] as String).trim()
        : (profile?['displayName'] as String?)?.trim() ??
            (profile?['handle'] as String?)?.trim() ??
            '';

    // artistId: flat OR uploaderId
    final artistId =
        (json['artistId'] as String?)?.trim().isNotEmpty == true
            ? (json['artistId'] as String).trim()
            : (json['uploaderId'] as String?)?.trim() ?? '';

    // artistHandle: flat OR profile.handle
    final artistHandle =
        (json['artistHandle'] as String?)?.trim().isNotEmpty == true
            ? (json['artistHandle'] as String).trim()
            : (profile?['handle'] as String?)?.trim() ?? '';

    return TrackDetailDto(
      trackId: trackId,
      title: (json['title'] as String?) ?? '',
      artist: artist,
      artistId: artistId,
      artistHandle: artistHandle,
      artworkUrl: json['coverArtUrl'] as String? ??
          json['cover_art_url'] as String?,
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