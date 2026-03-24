import '../../domain/entities/ManagedTrack.dart';
import '../../domain/entities/TrackManagementVisibility.dart';

class ManagedTrackDto {
  const ManagedTrackDto({
    required this.id,
    required this.title,
    required this.visibility,
    this.description,
    this.genreId,
    this.genreName,
    this.tags = const <String>[],
    this.artworkUrl,
    this.durationInSeconds,
    this.deletedAt,
  });

  factory ManagedTrackDto.fromJson(Map<String, dynamic> json) {
    return ManagedTrackDto(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      genreId: _parseGenreId(json),
      genreName: _parseGenreName(json),
      tags: _parseTags(json['tags']),
      visibility: trackManagementVisibilityFromApiValue(
        json['visibility']?.toString(),
      ),
      artworkUrl: json['artworkUrl']?.toString() ??
          json['artwork_url']?.toString() ??
          json['coverUrl']?.toString(),
      durationInSeconds: _parseInt(
        json['durationInSeconds'] ??
            json['duration_seconds'] ??
            json['duration'],
      ),
      deletedAt: json['deletedAt']?.toString(),
    );
  }

  final String id;
  final String title;
  final String? description;
  final int? genreId;
  final String? genreName;
  final List<String> tags;
  final TrackManagementVisibility visibility;
  final String? artworkUrl;
  final int? durationInSeconds;
  final String? deletedAt;

  ManagedTrack toEntity() {
    return ManagedTrack(
      id: id,
      title: title,
      description: description,
      genreId: genreId,
      genreName: genreName,
      tags: tags,
      visibility: visibility,
      artworkUrl: artworkUrl,
      durationInSeconds: durationInSeconds,
      isDeleted: deletedAt != null,
    );
  }
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

  if (genre is Map<String, dynamic>) {
    return genre['name']?.toString();
  }

  return json['genreName']?.toString() ?? json['genre_name']?.toString();
}

List<String> _parseTags(dynamic rawTags) {
  if (rawTags is! List) {
    return const <String>[];
  }

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

int? _parseInt(dynamic value) {
  if (value == null) {
    return null;
  }

  return int.tryParse(value.toString());
}
