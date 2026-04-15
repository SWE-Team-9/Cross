import 'dart:async';

import '../../models/player_state.dart';
import '../audio_player_service.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/core/models/track.dart';

import '../../audio/app_audio_handler.dart';
import '../../../main.dart';
import 'package:audio_service/audio_service.dart';

class JustAudioPlayerService implements AudioPlayerService {
  final AudioHandler _handler;

  JustAudioPlayerService({AudioHandler? handler})
      : _handler = handler ?? audioHandler {
    _listenToPlayer();
  }

  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();

  PlayerState _currentState = const PlayerState(
    status: PlayerStatus.idle,
    position: Duration.zero,
    duration: null,
  );

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  void _listenToPlayer() {
    _handler.playbackState.listen((playbackState) {
      PlayerStatus status;

      switch (playbackState.processingState) {
        case AudioProcessingState.loading:
        case AudioProcessingState.buffering:
          status = PlayerStatus.loading;
          break;

        case AudioProcessingState.ready:
          status = playbackState.playing
              ? PlayerStatus.playing
              : PlayerStatus.paused;
          break;

        case AudioProcessingState.completed:
          status = PlayerStatus.completed;
          break;

        default:
          status = PlayerStatus.idle;
      }

      _updateState(
        _currentState.copyWith(
          status: status,
          position: playbackState.updatePosition,
        ),
      );
    });

    _handler.mediaItem.listen((mediaItem) {
      _updateState(
        _currentState.copyWith(
          duration: mediaItem?.duration,
        ),
      );
    });
  }

  // 🔥 MAIN METHOD FOR SPRINT 4
  @override
  Future<void> playFromContext({
    required List<Track> tracks,
    required int startIndex,
    required String source,
  }) async {
    try {
      final appHandler = _handler as AppAudioHandler;

      final mediaItems = tracks.map((track) {
        return MediaItem(
          id: track.id,
          title: track.title,
          artist: track.artist,
          artUri:
              track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
          extras: {
            'url': track.audioUrl,
          },
        );
      }).toList();

      await appHandler.setQueue(mediaItems);
      await appHandler.skipToQueueItem(startIndex);
      await appHandler.play();

      _updateState(
        _currentState.copyWith(
          queue: tracks,
          currentIndex: startIndex,
          source: source,
        ),
      );

      GetIt.I<RecentlyPlayedCubit>().addTrack(tracks[startIndex]);
    } catch (e) {
      _updateState(
        _currentState.copyWith(
          status: PlayerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // 🔥 SINGLE TRACK FALLBACK
  @override
  Future<void> play(Track track) {
    return playFromContext(
      tracks: [track],
      startIndex: 0,
      source: "single",
    );
  }

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> resume() => _handler.play();

  @override
  Future<void> stop() => _handler.stop();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  void _updateState(PlayerState newState) {
    _currentState = newState;
    _playerStateController.add(newState);
  }

  @override
  Future<void> dispose() async {
    await _playerStateController.close();
  }
}
