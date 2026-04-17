import '../../domain/entities/managed_track.dart';
import '../../domain/entities/track_management_visibility.dart';
import '../../domain/entities/track_status.dart';
import '../../../playback/data/dto/waveform_parser.dart';
import '../../../playback/domain/entities/waveform_data.dart';

class ManagedTrackDto {
  const ManagedTrackDto({
    required this.id,
    required this.title,
    required this.visibility,
    this.status = TrackStatus.PROCESSING,
    this.waveformData = const WaveformData.empty(),
    this.description,
    this.genreId,
    this.genreName,
    this.tags = const <String>[],
    this.releaseDate,
    this.artworkUrl,
    this.durationInSeconds,
    this.secretToken,
    this.deletedAt,
  });

  factory ManagedTrackDto.fromJson(Map<String, dynamic> json) {
    return ManagedTrackDto(
      id: (json['id'] ?? json['trackId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: _parseDescription(json),
      genreId: _parseGenreId(json),
      genreName: _parseGenreName(json),
      tags: _parseTags(_extractRawTags(json)),
      releaseDate: _parseReleaseDate(json),
      visibility: trackManagementVisibilityFromApiValue(
        json['visibility']?.toString(),
      ),
      artworkUrl: json['artworkUrl']?.toString() ??
          json['artwork_url']?.toString() ??
          json['coverUrl']?.toString() ??
          json['coverArtUrl']?.toString(),
      durationInSeconds: _parseInt(
        json['durationInSeconds'] ??
            json['duration_seconds'] ??
            json['duration'] ??
            (json['durationMs'] != null
                ? ((json['durationMs'] as num) / 1000).round()
                : null),
      ),
      secretToken:
          json['secretToken']?.toString() ?? json['secret_token']?.toString(),
      deletedAt: json['deletedAt']?.toString(),
      status: TrackStatus.fromString(json['status']?.toString()),
      waveformData: WaveformParser.fromTrackJson(json),
    );
  }

  final String id;
  final String title;
  final String? description;
  final int? genreId;
  final String? genreName;
  final List<String> tags;
  final DateTime? releaseDate;
  final TrackManagementVisibility visibility;
  final String? artworkUrl;
  final int? durationInSeconds;
  final String? secretToken;
  final String? deletedAt;
  final TrackStatus status;
  final WaveformData waveformData;

  ManagedTrack toEntity() {
    return ManagedTrack(
      id: id,
      title: title,
      description: description,
      genreId: genreId,
      genreName: genreName,
      tags: tags,
      releaseDate: releaseDate,
      visibility: visibility,
      artworkUrl: artworkUrl,
      durationInSeconds: durationInSeconds,
      secretToken: secretToken,
      isDeleted: deletedAt != null,
      status: status,
      waveformData: waveformData,
    );
  }
}

String? _parseDescription(Map<String, dynamic> json) {
  final Map<String, dynamic>? metadata = _extractMetadataMap(json);
  final dynamic metadataDescription = metadata?['description'] ??
      metadata?['track_description'] ??
      metadata?['trackDescription'];

  final String? value = json['description']?.toString() ??
      json['track_description']?.toString() ??
      json['trackDescription']?.toString() ??
      metadataDescription?.toString();
  final String normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : normalized;
}

int? _parseGenreId(Map<String, dynamic> json) {
  final dynamic genre = json['genre'];
  if (genre is Map<String, dynamic>) {
    return _parseInt(genre['id']);
  }
  return _parseInt(json['genreId'] ?? json['genre_id']);
}

String? _parseGenreName(Map<String, dynamic> json) {
  final dynamic genre = json['genre'];

  if (genre is String) {
    final normalized = genre.trim();
    return normalized.isEmpty ? null : normalized;
  }

  if (genre is Map<String, dynamic>) {
    final value = genre['name']?.toString().trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  final String? value =
      json['genreName']?.toString() ?? json['genre_name']?.toString();
  final normalized = value?.trim();

  return (normalized == null || normalized.isEmpty) ? null : normalized;
}

List<String> _parseTags(dynamic rawTags) {
  if (rawTags is String) {
    return rawTags
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
  }

  if (rawTags is! List) return const <String>[];

  final List<String> result = <String>[];

  for (final tag in rawTags) {
    if (tag is String) {
      result.add(tag);
      continue;
    }
    if (tag is Map<String, dynamic>) {
      if (tag['name'] != null) {
        result.add(tag['name'].toString());
        continue;
      }
      final dynamic nestedTag = tag['tag'];
      if (nestedTag is Map<String, dynamic> && nestedTag['name'] != null) {
        result.add(nestedTag['name'].toString());
      }
    }
  }

  return result;
}

dynamic _extractRawTags(Map<String, dynamic> json) {
  // Supports known payload variants from track management/profile endpoints:
  // tags, tagList/tag_list, trackTags/track_tags, and metadata tag keys.
  final Map<String, dynamic>? metadata = _extractMetadataMap(json);
  final dynamic metadataTags = metadata?['tags'] ??
      metadata?['tag_list'] ??
      metadata?['tagList'] ??
      metadata?['track_tags'] ??
      metadata?['trackTags'];

  return json['tags'] ??
      json['tagList'] ??
      json['tag_list'] ??
      json['track_tags'] ??
      json['trackTags'] ??
      metadataTags;
}

Map<String, dynamic>? _extractMetadataMap(Map<String, dynamic> json) {
  final dynamic metadata =
      json['metadata'] ?? json['track_metadata'] ?? json['trackMetadata'];
  if (metadata is Map<String, dynamic>) {
    return metadata;
  }
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

DateTime? _parseReleaseDate(Map<String, dynamic> json) {
  final Map<String, dynamic>? metadata = _extractMetadataMap(json);
  final dynamic raw = json['releaseDate'] ??
      json['release_date'] ??
      json['releaseAt'] ??
      json['releasedAt'] ??
      metadata?['releaseDate'] ??
      metadata?['release_date'];
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}
