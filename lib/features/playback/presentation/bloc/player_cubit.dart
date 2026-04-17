import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';

import 'player_ui_state.dart';

class PlayerCubit extends Cubit<PlayerUIState> {
  final AudioPlayerService _audioService;
  StreamSubscription<PlayerState>? _subscription;

  PlayerCubit(this._audioService)
      : super(
          PlayerUIState(
            playerState: const PlayerState(
              status: PlayerStatus.idle,
              position: Duration.zero,
            ),
          ),
        ) {
    _listenToPlayer();
  }

  void _listenToPlayer() {
    _subscription = _audioService.playerStateStream.listen((playerState) {
      emit(state.copyWith(playerState: playerState));
    });
  }

  // 🔥 NEW CONTROL METHODS

  void hideMiniPlayer() {
    emit(state.copyWith(showMiniPlayer: false));
  }

  void showMiniPlayer() {
    emit(state.copyWith(showMiniPlayer: true));
  }

  Future<void> playFromContext({
    required List<Track> tracks,
    required int startIndex,
    String source = 'unknown',
  }) async {
    if (tracks.isEmpty) return;
    final safeIndex = startIndex.clamp(0, tracks.length - 1).toInt();
    final track = tracks[safeIndex];
    final played = Set<String>.from(state.playedTrackIds);

    if (state.currentTrack != null) {
      played.add(state.currentTrack!.id);
    }

    emit(state.copyWith(
      currentTrack: track,
      playedTrackIds: played,
      showMiniPlayer: true,
    ));

    await _audioService.playFromContext(
      tracks: tracks,
      startIndex: safeIndex,
      source: source,
    );
  }

  Future<void> play(Track track) async {
    await playFromContext(
      tracks: [track],
      startIndex: 0,
      source: 'single',
    );
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  Future<void> resume() async {
    await _audioService.resume();
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _audioService.setVolume(volume);
  }

  Future<void> stop() async {
    await _audioService.stop();
  }

  void openFullPlayer() {
    emit(state.copyWith(isFullScreen: true));
  }

  void closeFullPlayer() {
    emit(state.copyWith(isFullScreen: false));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
