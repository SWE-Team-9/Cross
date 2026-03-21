import 'package:equatable/equatable.dart';

import 'ManagedTrack.dart';
import 'TrackManagementVisibility.dart';

class TrackManagementForm extends Equatable {
  const TrackManagementForm({
    required this.title,
    required this.visibility,
    this.description,
    this.genreId,
    this.genreName,
    this.tags = const <String>[],
  });

  factory TrackManagementForm.fromTrack(ManagedTrack track) {
    return TrackManagementForm(
      title: track.title,
      description: track.description,
      genreId: track.genreId,
      genreName: track.genreName,
      tags: track.tags,
      visibility: track.visibility,
    );
  }

  final String title;
  final String? description;
  final int? genreId;
  final String? genreName;
  final List<String> tags;
  final TrackManagementVisibility visibility;

  String get normalizedTitle => title.trim();

  String? get normalizedDescription {
    final value = (description ?? '').trim();
    return value.isEmpty ? null : value;
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

    if (normalizedTitle.length > 255) {
      return 'Title must be 255 characters or fewer.';
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
    if (genreId == null) {
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
      if (tag.length > 50) {
        return 'Each tag must be 50 characters or fewer.';
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
        genreId != track.genreId ||
        !_sameTags(sanitizedTags, track.tags);
  }

  bool hasVisibilityChangeComparedTo(ManagedTrack track) {
    return visibility != track.visibility;
  }

  Map<String, dynamic> toMetadataRequestBody() {
    return <String, dynamic>{
      'title': normalizedTitle,
      'description': normalizedDescription,
      'genreId': genreId,
      'tags': sanitizedTags,
    };
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
    TrackManagementVisibility? visibility,
  }) {
    return TrackManagementForm(
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      genreId: clearGenreId ? null : (genreId ?? this.genreId),
      genreName: clearGenreName ? null : (genreName ?? this.genreName),
      tags: tags ?? this.tags,
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
        visibility,
      ];
}

String? _normalizeNullable(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : normalized;
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
