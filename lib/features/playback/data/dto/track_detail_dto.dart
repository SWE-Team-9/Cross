import '../../domain/entities/track_details.dart';
import '../../domain/entities/waveform_data.dart';

class TrackDetailDto {
  const TrackDetailDto({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.artistHandle,
    this.slug,
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
  final String? slug;
  final String? artworkUrl;
  final int? durationMs;
  final int likesCount;
  final int repostsCount;
  final List<dynamic>? waveformRaw;

  factory TrackDetailDto.fromJson(Map<String, dynamic> json) {
    // ✅ الحل — بنجرب كل الأسماء المحتملة للـ ID
    final trackId = _firstNonEmpty([
      json['trackId'],
      json['trackid'],
      json['id'],
      json['Id'],
      json['track_id'],
    ]);

    final uploader = json['uploader'] as Map<String, dynamic>?;
    final profile = uploader?['profile'] as Map<String, dynamic>?;

    final artist = (json['artist'] as String?)?.trim().isNotEmpty == true
        ? (json['artist'] as String).trim()
        : (profile?['displayName'] as String?)?.trim() ??
            (profile?['handle'] as String?)?.trim() ??
            '';

    final artistId = _firstNonEmpty([
      json['artistId'],
      json['artist_id'],
      json['uploaderId'],
    ]);

    final artistHandle = _firstNonEmpty([
      json['artistHandle'],
      json['artist_handle'],
      profile?['handle'],
    ]);

    final slug = (json['slug'] as String?)?.trim().isNotEmpty == true
        ? (json['slug'] as String).trim()
        : null;

    return TrackDetailDto(
      trackId: trackId,
      title: (json['title'] as String?) ?? '',
      artist: artist,
      artistId: artistId,
      artistHandle: artistHandle,
      slug: slug,
      artworkUrl:
          json['coverArtUrl'] as String? ?? json['cover_art_url'] as String?,
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
      slug: slug,
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

  // ✅ helper — بياخد أول قيمة غير فاضية من اللستة
  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
