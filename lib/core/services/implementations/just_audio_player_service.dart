import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;

import '../../models/player_state.dart';
import '../audio_player_service.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/core/models/track.dart';

class JustAudioPlayerService implements AudioPlayerService {
  final ja.AudioPlayer _player = ja.AudioPlayer();

  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();

  PlayerState _currentState = const PlayerState(
    status: PlayerStatus.idle,
    position: Duration.zero,
    duration: null,
  );

  JustAudioPlayerService() {
    _listenToPlayer();
  }

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  void _listenToPlayer() {
    _player.playerStateStream.listen((state) {
      final processingState = state.processingState;

      PlayerStatus status;

      if (processingState == ja.ProcessingState.loading ||
          processingState == ja.ProcessingState.buffering) {
        status = PlayerStatus.loading;
      } else if (processingState == ja.ProcessingState.ready) {
        status = state.playing ? PlayerStatus.playing : PlayerStatus.paused;
      } else if (processingState == ja.ProcessingState.completed) {
        status = PlayerStatus.completed;
      } else {
        status = PlayerStatus.idle;
      }

      _updateState(
        _currentState.copyWith(
          status: status,
          position: _player.position,
          duration: _player.duration,
        ),
      );
    });

    _player.positionStream.listen((position) {
      _updateState(
        _currentState.copyWith(position: position),
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
      _updateState(
        _currentState.copyWith(
          status: PlayerStatus.loading,
          currentTrackId: track.id,
        ),
      );

      await _player.setUrl(track.audioUrl);

      // 🔥 Recently Played integration
      GetIt.I<RecentlyPlayedCubit>().addTrack(track);

      await _player.seek(Duration.zero);

      await _player.play();
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
  Future<void> pause() async {
    await _player.pause();

    _updateState(
      _currentState.copyWith(status: PlayerStatus.paused),
    );
  }

  @override
  Future<void> resume() async {
    await _player.play();

    _updateState(
      _currentState.copyWith(status: PlayerStatus.playing),
    );
  }

  @override
  Future<void> stop() async {
    await _player.stop();

    _updateState(
      _currentState.copyWith(
        status: PlayerStatus.idle,
        position: Duration.zero,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    await _playerStateController.close();
  }
}
