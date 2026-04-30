import 'package:equatable/equatable.dart';

import 'managed_track.dart';
import 'track_genre.dart';
import 'track_management_visibility.dart';

class TrackManagementForm extends Equatable {
  const TrackManagementForm({
    required this.title,
    required this.visibility,
    this.description,
    this.genreId,
    this.genreName,
    this.tags = const <String>[],
    this.releaseDate,
  });

  factory TrackManagementForm.fromTrack(ManagedTrack track) {
    return TrackManagementForm(
      title: track.title,
      description: track.description,
      genreId: track.genreId,
      genreName: track.genreName,
      tags: track.tags,
      releaseDate: track.releaseDate,
      visibility: track.visibility,
    );
  }

  final String title;
  final String? description;
  final int? genreId;
  final String? genreName;
  final List<String> tags;
  final DateTime? releaseDate;
  final TrackManagementVisibility visibility;

  String get normalizedTitle => title.trim();

  String? get normalizedDescription {
    final value = (description ?? '').trim();
    return value.isEmpty ? null : value;
  }

  String? get normalizedGenreName {
    return normalizeTrackGenreName(genreName);
  }

  List<String> get sanitizedTags {
    final List<String> result = <String>[];
    final Set<String> seen = <String>{};

    for (final rawTag in tags) {
      final trimmed = rawTag.trim();
      final normalized = trimmed.toLowerCase();

      if (trimmed.isEmpty || seen.contains(normalized)) {
        continue;
      }

      if (result.length >= 10) {
        break;
      }

      result.add(trimmed);
      seen.add(normalized);
    }

    return result;
  }

  String? get titleValidationError {
    if (normalizedTitle.isEmpty) {
      return 'Title is required.';
    }

    if (normalizedTitle.length > 100) {
      return 'Title must be 100 characters or fewer.';
    }

    return null;
  }

  String? get descriptionValidationError {
    final value = normalizedDescription;
    if (value != null && value.length > 5000) {
      return 'Description must be 5000 characters or fewer.';
    }

    return null;
  }

  String? get genreValidationError {
    if (normalizedGenreName == null) {
      return 'Please choose a genre.';
    }

    return null;
  }

  String? get tagsValidationError {
    final tags = sanitizedTags;

    if (tags.length > 10) {
      return 'You can add up to 10 tags only.';
    }

    for (final tag in tags) {
      if (tag.length > 30) {
        return 'Each tag must be 30 characters or fewer.';
      }
    }

    return null;
  }

  bool get isMetadataValid =>
      titleValidationError == null &&
      descriptionValidationError == null &&
      genreValidationError == null &&
      tagsValidationError == null;

  bool hasMetadataChangesComparedTo(ManagedTrack track) {
    return normalizedTitle != track.title.trim() ||
        normalizedDescription != _normalizeNullable(track.description) ||
        normalizedGenreName != _normalizeGenreNullable(track.genreName) ||
        _normalizeDateOnly(releaseDate) !=
            _normalizeDateOnly(track.releaseDate) ||
        !_sameTags(sanitizedTags, track.tags);
  }

  bool hasVisibilityChangeComparedTo(ManagedTrack track) {
    return visibility != track.visibility;
  }

  Map<String, dynamic> toMetadataRequestBody() {
    final Map<String, dynamic> body = <String, dynamic>{
      'title': normalizedTitle,
      'genre': normalizedGenreName,
      'tags': sanitizedTags,
    };

    if (normalizedDescription != null) {
      body['description'] = normalizedDescription;
    }
    if (releaseDate != null) {
      body['releaseDate'] = releaseDate!.toIso8601String().split('T').first;
    }

    return body;
  }

  Map<String, dynamic> toVisibilityRequestBody() {
    return <String, dynamic>{
      'visibility': visibility.apiValue,
    };
  }

  TrackManagementForm copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    int? genreId,
    bool clearGenreId = false,
    String? genreName,
    bool clearGenreName = false,
    List<String>? tags,
    DateTime? releaseDate,
    bool clearReleaseDate = false,
    TrackManagementVisibility? visibility,
  }) {
    return TrackManagementForm(
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      genreId: clearGenreId ? null : (genreId ?? this.genreId),
      genreName: clearGenreName ? null : (genreName ?? this.genreName),
      tags: tags ?? this.tags,
      releaseDate: clearReleaseDate ? null : (releaseDate ?? this.releaseDate),
      visibility: visibility ?? this.visibility,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        genreId,
        genreName,
        tags,
        releaseDate,
        visibility,
      ];
}

String? _normalizeNullable(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : normalized;
}

String? _normalizeGenreNullable(String? value) {
  return normalizeTrackGenreName(value);
}

bool _sameTags(List<String> first, List<String> second) {
  final List<String> normalizedFirst = first
      .map((tag) => tag.trim().toLowerCase())
      .where((tag) => tag.isNotEmpty)
      .toList();

  final List<String> normalizedSecond = second
      .map((tag) => tag.trim().toLowerCase())
      .where((tag) => tag.isNotEmpty)
      .toList();

  if (normalizedFirst.length != normalizedSecond.length) {
    return false;
  }

  for (int index = 0; index < normalizedFirst.length; index++) {
    if (normalizedFirst[index] != normalizedSecond[index]) {
      return false;
    }
  }

  return true;
}

String? _normalizeDateOnly(DateTime? value) {
  if (value == null) return null;
  return value.toIso8601String().split('T').first;
}
