import 'dart:async';

import '../../models/player_state.dart';
import '../audio_player_service.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/core/models/track.dart';

import '../../audio/app_audio_handler.dart'; // ✅ FIXED IMPORT
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

  void _updateState(PlayerState newState) {
    _currentState = newState;
    _playerStateController.add(newState);
  }

  @override
  Future<void> play(Track track) async {
    try {
      // ✅ REAL APP: play actual audio
      if (_handler is AppAudioHandler) {
        final realHandler = _handler as AppAudioHandler;

        await realHandler.playTrack(
          url: track.audioUrl,
          title: track.title,
          artist: track.artist,
          artworkUrl: track.artworkUrl,
        );
      }

      // ✅ TEST ENV: do nothing (no crash, no fake add)

      GetIt.I<RecentlyPlayedCubit>().addTrack(track);
    } catch (e) {
      _updateState(
        _currentState.copyWith(
          status: PlayerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> resume() => _handler.play();

  @override
  Future<void> stop() => _handler.stop();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  @override
  Future<void> dispose() async {
    await _playerStateController.close();
  }
}
