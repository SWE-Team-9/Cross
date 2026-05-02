import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_clone/core/models/track.dart';

import '../../domain/usecases/get_recently_played.dart';

class RecentlyPlayedCubit extends Cubit<List<Track>> {
  static const _localHistoryKey = 'recent_tracks_local';

  RecentlyPlayedCubit({
    this.getRecentlyPlayed,
    this.recordRecentlyPlayed,
  }) : super(<Track>[]);

  final GetRecentlyPlayed? getRecentlyPlayed;
  final RecordRecentlyPlayed? recordRecentlyPlayed;

  Future<void> loadListeningHistory() async {
    final localTracks = await _loadLocalHistory();
    if (localTracks.isNotEmpty) {
      emit(localTracks);
    }

    final loader = getRecentlyPlayed;
    if (loader == null) return;

    try {
      final tracks = await loader();
      if (tracks.isNotEmpty) {
        final merged = _mergeTracks(tracks, localTracks);
        emit(merged);
        unawaited(_saveLocalHistory(merged));
      }
    } catch (_) {
      // keep in-memory state as fallback
    }
  }

  void addTrack(Track track) {
    final updated = List<Track>.from(state);

    updated.removeWhere((t) => t.id == track.id);

    updated.insert(0, track);

    if (updated.length > 20) {
      updated.removeLast();
    }

    emit(updated);
    unawaited(_saveLocalHistory(updated));

    final recorder = recordRecentlyPlayed;
    if (recorder != null) {
      unawaited(recordTrackPlay(track.id));
    }
  }

  Future<void> recordTrackPlay(String trackId) async {
    final recorder = recordRecentlyPlayed;
    if (recorder == null) return;
    try {
      await recorder(trackId);
    } catch (_) {
      // ignore remote errors for optimistic UX
    }
  }

  void clear() {
    emit(<Track>[]);
    unawaited(_saveLocalHistory(const <Track>[]));
  }

  List<Track> _mergeTracks(List<Track> primary, List<Track> fallback) {
    final merged = <Track>[];
    final seenIds = <String>{};

    for (final track in [...primary, ...fallback]) {
      if (track.id.isEmpty || !seenIds.add(track.id)) continue;
      merged.add(track);
      if (merged.length >= 20) break;
    }

    return merged;
  }

  Future<List<Track>> _loadLocalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_localHistoryKey);
      if (rawJson == null) return const <Track>[];

      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const <Track>[];

      return decoded
          .map((value) => _trackFromJson(_asMap(value)))
          .where((track) => track.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <Track>[];
    }
  }

  Future<void> _saveLocalHistory(List<Track> tracks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _localHistoryKey,
        jsonEncode(
          tracks.take(20).map(_trackToJson).toList(growable: false),
        ),
      );
    } catch (_) {
      // local history is a convenience cache
    }
  }
}

Map<String, dynamic> _trackToJson(Track track) {
  return <String, dynamic>{
    'id': track.id,
    'title': track.title,
    'artist': track.artist,
    'audioUrl': track.audioUrl,
    'artworkUrl': track.artworkUrl,
    'handle': track.handle,
    'artistId': track.artistId,
    'likesCount': track.likesCount,
    'repostsCount': track.repostsCount,
    'durationMs': track.durationMs,
    'localPath': track.localPath,
  };
}

Track _trackFromJson(Map<String, dynamic> json) {
  return Track(
    id: _asString(json['id']),
    title: _asString(json['title'], fallback: 'Untitled'),
    artist: _asString(json['artist'], fallback: 'Unknown artist'),
    audioUrl: _asString(json['audioUrl']),
    artworkUrl: _asNullableString(json['artworkUrl']),
    handle: _asNullableString(json['handle']),
    artistId: _asNullableString(json['artistId']),
    likesCount: _asInt(json['likesCount']),
    repostsCount: _asInt(json['repostsCount']),
    durationMs: _asNullableInt(json['durationMs']),
    localPath: _asNullableString(json['localPath']),
  );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _asString(dynamic value, {String fallback = ''}) {
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? fallback : parsed;
}

String? _asNullableString(dynamic value) {
  final parsed = _asString(value);
  return parsed.isEmpty ? null : parsed;
}

int _asInt(dynamic value) => _asNullableInt(value) ?? 0;

int? _asNullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
