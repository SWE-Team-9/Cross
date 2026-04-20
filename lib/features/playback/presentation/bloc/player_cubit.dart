import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';

import 'player_ui_state.dart';

class PlayerCubit extends Cubit<PlayerUIState> {
  static const String _queueSource = 'queue';
  static const Duration _pendingSwitchMaxAge = Duration(seconds: 8);

  final AudioPlayerService _audioService;
  final GetTrackDetailUseCase? _getTrackDetail;
  StreamSubscription<PlayerState>? _subscription;
  String? _pendingRequestedTrackId;
  DateTime? _pendingRequestedAt;

  PlayerCubit(
    this._audioService, {
    GetTrackDetailUseCase? getTrackDetail,
  })  : _getTrackDetail = getTrackDetail,
        super(
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
      final localQueue = state.playerState.queue;
      final incomingTrack = _trackFromServiceState(playerState) ??
          _trackById(playerState.currentTrackId, playerState.queue) ??
          _trackById(playerState.currentTrackId, localQueue);

      if (_pendingRequestedTrackId != null &&
          incomingTrack?.id == _pendingRequestedTrackId) {
        _clearPendingTrackSwitch();
      }

      final hasQueueMismatch =
          localQueue.isNotEmpty && !_sameQueue(localQueue, playerState.queue);
      final sameCurrentTrack =
          incomingTrack != null && incomingTrack.id == state.currentTrack?.id;
      final hasPendingSwitch = _hasPendingTrackSwitch;
      final shouldKeepLocalQueue =
          hasQueueMismatch && (sameCurrentTrack || hasPendingSwitch);
      final mergedPlayerState = shouldKeepLocalQueue
          ? playerState.copyWith(
              queue: localQueue,
              currentIndex: state.currentIndex,
            )
          : playerState;

      final serviceTrack = _trackFromServiceState(mergedPlayerState) ??
          _trackById(
            mergedPlayerState.currentTrackId,
            mergedPlayerState.queue,
          ) ??
          _trackById(
            mergedPlayerState.currentTrackId,
            localQueue,
          );

      final nextTrack = serviceTrack ?? state.currentTrack;
      emit(
        state.copyWith(
          playerState: mergedPlayerState,
          currentTrack: nextTrack,
        ),
      );
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
    final playableTracks = await _resolvePlayableTrackAt(tracks, safeIndex);
    if (playableTracks == null) return;

    final track = playableTracks[safeIndex];
    _markPendingTrackSwitch(track.id);
    final played = Set<String>.from(state.playedTrackIds);

    if (state.currentTrack != null) {
      played.add(state.currentTrack!.id);
    }

    emit(state.copyWith(
      playerState: state.playerState.copyWith(
        queue: playableTracks,
        currentIndex: safeIndex,
        source: source,
      ),
      currentTrack: track,
      playedTrackIds: played,
      showMiniPlayer: true,
    ));

    await _audioService.playFromContext(
      tracks: playableTracks,
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

  Future<void> setRepeatMode(AppRepeatMode mode) async {
    emit(
      state.copyWith(
        playerState: state.playerState.copyWith(repeatMode: mode),
      ),
    );
    await _audioService.setRepeatMode(mode);
  }

  Future<void> cycleRepeatMode() async {
    final nextMode = switch (state.repeatMode) {
      AppRepeatMode.off => AppRepeatMode.one,
      AppRepeatMode.one => AppRepeatMode.all,
      AppRepeatMode.all => AppRepeatMode.off,
    };
    await setRepeatMode(nextMode);
  }

  Future<void> stop() async {
    await _audioService.stop();
  }

  Future<void> playNext() async {
    final tracks = state.queue;
    final currentIndex = state.currentIndex;
    if (tracks.isEmpty || currentIndex < 0) return;
    final isLastTrack = currentIndex >= tracks.length - 1;
    if (isLastTrack && state.repeatMode != AppRepeatMode.all) return;
    final nextIndex = isLastTrack ? 0 : currentIndex + 1;

    await playFromContext(
      tracks: tracks,
      startIndex: nextIndex,
      source: state.playerState.source ?? _queueSource,
    );
  }

  Future<void> playPrevious() async {
    final tracks = state.queue;
    final currentIndex = state.currentIndex;
    if (tracks.isEmpty || currentIndex < 0) return;
    final isFirstTrack = currentIndex <= 0;
    if (isFirstTrack && state.repeatMode != AppRepeatMode.all) return;
    final previousIndex = isFirstTrack ? tracks.length - 1 : currentIndex - 1;

    await playFromContext(
      tracks: tracks,
      startIndex: previousIndex,
      source: state.playerState.source ?? _queueSource,
    );
  }

  Future<void> addPlayNext(Track track) async {
    final queue = List<Track>.from(state.queue);
    final currentTrack = state.currentTrack;
    if (currentTrack?.id == track.id) return;

    if (queue.isEmpty || state.currentIndex < 0) {
      await playFromContext(
        tracks: [track],
        startIndex: 0,
        source: _queueSource,
      );
      return;
    }

    final currentId = currentTrack?.id;
    queue.removeWhere((item) => item.id == track.id);

    var currentIndex = currentId == null
        ? state.currentIndex
        : queue.indexWhere((item) => item.id == currentId);
    if (currentIndex < 0 || currentIndex >= queue.length) {
      currentIndex =
          queue.isEmpty ? -1 : state.currentIndex.clamp(0, queue.length - 1);
    }

    final insertAt = currentIndex < 0
        ? 0
        : (currentIndex + 1).clamp(0, queue.length).toInt();
    queue.insert(insertAt, track);

    emit(
      state.copyWith(
        playerState: state.playerState.copyWith(
          queue: queue,
          currentIndex: currentIndex < 0 ? 0 : currentIndex,
        ),
        showMiniPlayer: true,
      ),
    );
  }

  Future<void> addPlayLast(Track track) async {
    final queue = List<Track>.from(state.queue);
    final currentTrack = state.currentTrack;
    if (currentTrack?.id == track.id) return;

    if (queue.isEmpty || state.currentIndex < 0) {
      await playFromContext(
        tracks: [track],
        startIndex: 0,
        source: _queueSource,
      );
      return;
    }

    queue.removeWhere((item) => item.id == track.id);
    queue.add(track);

    final currentIndex = currentTrack == null
        ? state.currentIndex
        : queue.indexWhere((item) => item.id == currentTrack.id);

    emit(
      state.copyWith(
        playerState: state.playerState.copyWith(
          queue: queue,
          currentIndex: currentIndex >= 0 ? currentIndex : state.currentIndex,
        ),
        showMiniPlayer: true,
      ),
    );
  }

  Future<List<Track>?> _resolvePlayableTrackAt(
    List<Track> tracks,
    int index,
  ) async {
    final resolvedTracks = List<Track>.from(tracks);
    final selected = resolvedTracks[index];
    if (selected.audioUrl.trim().isNotEmpty) {
      return resolvedTracks;
    }

    final getTrackDetail = _getTrackDetail;
    if (getTrackDetail == null) return null;

    final result = await getTrackDetail(selected.id);
    final detail = result.detail;
    if (result.failure != null || detail == null) return null;

    resolvedTracks[index] = detail.toPlaybackTrack();
    return resolvedTracks;
  }

  Track? _trackFromServiceState(PlayerState playerState) {
    final queue = playerState.queue;
    final index = playerState.currentIndex;
    if (queue.isEmpty || index < 0 || index >= queue.length) return null;
    return queue[index];
  }

  Track? _trackById(String? trackId, List<Track> tracks) {
    if (trackId == null || tracks.isEmpty) return null;
    for (final track in tracks) {
      if (track.id == trackId) return track;
    }
    return null;
  }

  bool get _hasPendingTrackSwitch {
    final pendingAt = _pendingRequestedAt;
    if (_pendingRequestedTrackId == null || pendingAt == null) return false;

    if (DateTime.now().difference(pendingAt) > _pendingSwitchMaxAge) {
      _clearPendingTrackSwitch();
      return false;
    }

    return true;
  }

  void _markPendingTrackSwitch(String trackId) {
    _pendingRequestedTrackId = trackId;
    _pendingRequestedAt = DateTime.now();
  }

  void _clearPendingTrackSwitch() {
    _pendingRequestedTrackId = null;
    _pendingRequestedAt = null;
  }

  bool _sameQueue(List<Track> left, List<Track> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i].id != right[i].id) return false;
    }
    return true;
  }

  void openFullPlayer() {
    emit(state.copyWith(isFullScreen: true));
  }

  void closeFullPlayer() {
    emit(state.copyWith(isFullScreen: false));
  }

  @override
  Future<void> close() {
    _clearPendingTrackSwitch();
    _subscription?.cancel();
    return super.close();
  }
}
