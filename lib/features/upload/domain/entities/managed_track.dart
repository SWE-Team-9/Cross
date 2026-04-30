import 'package:equatable/equatable.dart';

import 'track_management_visibility.dart';
import 'track_status.dart';
import '../../../playback/domain/entities/waveform_data.dart';

class ManagedTrack extends Equatable {
  const ManagedTrack({
    required this.id,
    required this.title,
    this.artistName,
    this.artistHandle,
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
    this.isDeleted = false,
    this.likesCount = 0,
    this.repostsCount = 0,
  });

  final String id;
  final String title;
  final String? artistName;
  final String? artistHandle;
  final String? description;
  final int? genreId;
  final String? genreName;
  final List<String> tags;
  final DateTime? releaseDate;
  final TrackManagementVisibility visibility;
  final String? artworkUrl;
  final int? durationInSeconds;
  final String? secretToken;
  final bool isDeleted;

  final TrackStatus status;
  final WaveformData waveformData;
  final int likesCount;
  final int repostsCount;

  ManagedTrack copyWith({
    String? id,
    String? title,
    String? artistName,
    bool clearArtistName = false,
    String? artistHandle,
    bool clearArtistHandle = false,
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
    String? artworkUrl,
    bool clearArtworkUrl = false,
    int? durationInSeconds,
    bool clearDurationInSeconds = false,
    String? secretToken,
    bool clearSecretToken = false,
    bool? isDeleted,
    int? likesCount,
    int? repostsCount,
    TrackStatus? status,
    WaveformData? waveformData,
  }) {
    return ManagedTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: clearArtistName ? null : (artistName ?? this.artistName),
      artistHandle:
          clearArtistHandle ? null : (artistHandle ?? this.artistHandle),
      description: clearDescription ? null : (description ?? this.description),
      genreId: clearGenreId ? null : (genreId ?? this.genreId),
      genreName: clearGenreName ? null : (genreName ?? this.genreName),
      tags: tags ?? this.tags,
      releaseDate: clearReleaseDate ? null : (releaseDate ?? this.releaseDate),
      visibility: visibility ?? this.visibility,
      artworkUrl: clearArtworkUrl ? null : (artworkUrl ?? this.artworkUrl),
      durationInSeconds: clearDurationInSeconds
          ? null
          : (durationInSeconds ?? this.durationInSeconds),
      secretToken: clearSecretToken ? null : (secretToken ?? this.secretToken),
      isDeleted: isDeleted ?? this.isDeleted,
      likesCount: likesCount ?? this.likesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      status: status ?? this.status,
      waveformData: waveformData ?? this.waveformData,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artistName,
        artistHandle,
        description,
        genreId,
        genreName,
        tags,
        releaseDate,
        visibility,
        artworkUrl,
        durationInSeconds,
        secretToken,
        isDeleted,
        likesCount,
        repostsCount,
        status,
        waveformData,
      ];
}
