import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/playback/data/repositories/queue_repository.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';

import 'player_ui_state.dart';

class PlayerCubit extends Cubit<PlayerUIState> {
  static const String _queueSource = 'queue';
  static const Duration _pendingSwitchMaxAge = Duration(seconds: 8);

  final AudioPlayerService _audioService;
  final GetTrackDetailUseCase? _getTrackDetail;
  final QueueRepository? _queueRepository;

  StreamSubscription<PlayerState>? _subscription;
  String? _pendingRequestedTrackId;
  DateTime? _pendingRequestedAt;

  final Set<String> _prefetchedIds = {};

  PlayerCubit(
    this._audioService, {
    GetTrackDetailUseCase? getTrackDetail,
    QueueRepository? queueRepository,
  })  : _getTrackDetail = getTrackDetail,
        _queueRepository = queueRepository,
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
      final shouldClearCurrentTrack = playerState.status == PlayerStatus.idle &&
          playerState.currentTrackId == null &&
          playerState.queue.isEmpty &&
          !_hasPendingTrackSwitch;
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
              mergedPlayerState.currentTrackId, mergedPlayerState.queue) ??
          _trackById(mergedPlayerState.currentTrackId, localQueue);

      final nextTrack =
          shouldClearCurrentTrack ? null : serviceTrack ?? state.currentTrack;
      emit(state.copyWith(
        playerState: mergedPlayerState,
        currentTrack: nextTrack,
        clearCurrentTrack: shouldClearCurrentTrack,
        showMiniPlayer: shouldClearCurrentTrack ? false : state.showMiniPlayer,
      ));

      _prefetchNextTrackInBackground(mergedPlayerState);
    });
  }

  // ── Prefetch in background ───────────────────────────────────────────────

  void _prefetchNextTrackInBackground(PlayerState playerState) {
    final queue = playerState.queue;
    final currentIndex = playerState.currentIndex;
    if (queue.isEmpty || currentIndex < 0) return;

    final nextIndex = currentIndex + 1;
    if (nextIndex >= queue.length) return;

    final nextTrack = queue[nextIndex];
    if (nextTrack.audioUrl.trim().isNotEmpty) return;
    if (_prefetchedIds.contains(nextTrack.id)) return;

    _prefetchedIds.add(nextTrack.id);
    _resolveAndUpdateQueue(queue, nextIndex);
  }

  Future<void> _resolveAndUpdateQueue(List<Track> queue, int index) async {
    final getTrackDetail = _getTrackDetail;
    if (getTrackDetail == null) return;

    final target = queue[index];
    final result = await getTrackDetail(target.id);
    final detail = result.detail;
    if (result.failure != null || detail == null) return;
    if (isClosed) return;

    final resolved = List<Track>.from(state.playerState.queue);
    final currentIdx = resolved.indexWhere((t) => t.id == target.id);
    if (currentIdx == -1) return;

    resolved[currentIdx] = detail.toPlaybackTrack();

    emit(state.copyWith(
      playerState: state.playerState.copyWith(queue: resolved),
    ));
  }

  // ── Mini Player visibility ───────────────────────────────────────────────

  void hideMiniPlayer() => emit(state.copyWith(showMiniPlayer: false));
  void showMiniPlayer() => emit(state.copyWith(showMiniPlayer: true));

  // ── Core playback ────────────────────────────────────────────────────────

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

    final previousSource = state.playerState.source;
    final sourceChanged = previousSource != null && previousSource != source;

    final played =
        sourceChanged ? <String>{} : Set<String>.from(state.playedTrackIds);

    if (state.currentTrack != null && !sourceChanged) {
      played.add(state.currentTrack!.id);
    }

    if (sourceChanged) _prefetchedIds.clear();

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

    // ✅ sync الـ queue الجديدة مع الـ backend
    _syncQueueToBackend(playableTracks, safeIndex);

    await _audioService.playFromContext(
      tracks: playableTracks,
      startIndex: safeIndex,
      source: source,
    );
  }

  Future<void> play(Track track) async {
    await playFromContext(tracks: [track], startIndex: 0, source: 'single');
  }

  Future<void> pause() async => await _audioService.pause();
  Future<void> resume() async => await _audioService.resume();

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) async =>
      await _audioService.seek(position);

  Future<void> setVolume(double volume) async =>
      await _audioService.setVolume(volume);

  Future<void> setRepeatMode(AppRepeatMode mode) async {
    emit(state.copyWith(
      playerState: state.playerState.copyWith(repeatMode: mode),
    ));
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
    _clearPendingTrackSwitch();
    _prefetchedIds.clear();

    emit(PlayerUIState(
      playerState: PlayerState(
        status: PlayerStatus.idle,
        position: Duration.zero,
        volume: state.volume,
        repeatMode: state.repeatMode,
      ),
      showMiniPlayer: false,
    ));

    await _audioService.stop();
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  Future<void> playNext() async {
    final tracks = state.queue;
    final currentIndex = state.currentIndex;
    if (tracks.isEmpty || currentIndex < 0) return;

    final isLastTrack = currentIndex >= tracks.length - 1;
    if (isLastTrack && state.repeatMode != AppRepeatMode.all) return;

    final nextIndex = isLastTrack ? 0 : currentIndex + 1;

    // ✅ أبلغ الـ backend بالـ next
    _queueRepository?.next().ignore();

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

    // ✅ أبلغ الـ backend بالـ previous
    _queueRepository?.previous().ignore();

    await playFromContext(
      tracks: tracks,
      startIndex: previousIndex,
      source: state.playerState.source ?? _queueSource,
    );
  }

  // ── Queue manipulation ───────────────────────────────────────────────────

  Future<void> addPlayNext(Track track) async {
    final queue = List<Track>.from(state.queue);
    final currentTrack = state.currentTrack;
    if (currentTrack?.id == track.id) return;

    if (queue.isEmpty || state.currentIndex < 0) {
      await playFromContext(
          tracks: [track], startIndex: 0, source: _queueSource);
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

    final safeIndex = currentIndex < 0 ? 0 : currentIndex;

    emit(state.copyWith(
      playerState: state.playerState.copyWith(
        queue: queue,
        currentIndex: safeIndex,
      ),
      showMiniPlayer: true,
    ));

    // ✅ sync مع الـ backend
    _syncQueueToBackend(queue, safeIndex);
  }

  Future<void> addPlayLast(Track track) async {
    final queue = List<Track>.from(state.queue);
    final currentTrack = state.currentTrack;
    if (currentTrack?.id == track.id) return;

    if (queue.isEmpty || state.currentIndex < 0) {
      await playFromContext(
          tracks: [track], startIndex: 0, source: _queueSource);
      return;
    }

    queue.removeWhere((item) => item.id == track.id);
    queue.add(track);

    final currentIndex = currentTrack == null
        ? state.currentIndex
        : queue.indexWhere((item) => item.id == currentTrack.id);

    final safeIndex = currentIndex >= 0 ? currentIndex : state.currentIndex;

    emit(state.copyWith(
      playerState: state.playerState.copyWith(
        queue: queue,
        currentIndex: safeIndex,
      ),
      showMiniPlayer: true,
    ));

    // ✅ sync مع الـ backend
    _syncQueueToBackend(queue, safeIndex);
  }

  void reorderQueue(List<Track> newQueue) {
    final currentTrackId = state.currentTrack?.id;
    final newIndex = currentTrackId == null
        ? state.currentIndex
        : newQueue.indexWhere((t) => t.id == currentTrackId);

    final safeIndex = newIndex >= 0 ? newIndex : state.currentIndex;

    emit(state.copyWith(
      playerState: state.playerState.copyWith(
        queue: newQueue,
        currentIndex: safeIndex,
      ),
    ));

    // ✅ sync مع الـ backend
    _syncQueueToBackend(newQueue, safeIndex);
  }

  // ── Backend sync ─────────────────────────────────────────────────────────

  /// fire-and-forget — يبعت الـ queue للـ backend بدون ما ننتظر
  void _syncQueueToBackend(List<Track> queue, int currentIndex) {
    if (queue.isEmpty) return;
    final safeIndex = currentIndex.clamp(0, queue.length - 1);
    _queueRepository
        ?.loadQueue(
          trackIds: queue.map((t) => t.id).toList(),
          startIndex: safeIndex,
        )
        .ignore();
  }

  // ── Full player visibility ───────────────────────────────────────────────

  void openFullPlayer() => emit(state.copyWith(isFullScreen: true));
  void closeFullPlayer() => emit(state.copyWith(isFullScreen: false));

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<List<Track>?> _resolvePlayableTrackAt(
    List<Track> tracks,
    int index,
  ) async {
    final resolvedTracks = _withOfflinePaths(tracks);
    final selected = resolvedTracks[index];
    if (selected.localPath != null && selected.localPath!.trim().isNotEmpty) {
      return resolvedTracks;
    }

    final getTrackDetail = _getTrackDetail;
    if (getTrackDetail == null) return resolvedTracks;

    if (selected.audioUrl.trim().isNotEmpty) return resolvedTracks;

    final result = await getTrackDetail(selected.id);
    final detail = result.detail;

    if (result.failure == null && detail != null) {
      // ✅ ALWAYS update waveform
      emit(state.copyWith(
        waveform: detail.waveformData,
      ));

      // ✅ Only replace track if needed
      if (selected.audioUrl.trim().isEmpty &&
          (selected.localPath == null || selected.localPath!.trim().isEmpty)) {
        resolvedTracks[index] = _withOfflinePath(detail.toPlaybackTrack());
      }
    }

    return resolvedTracks;
  }

  List<Track> _withOfflinePaths(List<Track> tracks) {
    return tracks.map(_withOfflinePath).toList();
  }

  Track _withOfflinePath(Track track) {
    final offlineCubit = _offlineCubit();
    if (offlineCubit == null || !offlineCubit.isDownloaded(track.id)) {
      return track;
    }

    final localPath = offlineCubit.getPath(track.id);
    if (localPath == null || localPath.trim().isEmpty) return track;
    return track.copyWith(localPath: localPath);
  }

  OfflineCubit? _offlineCubit() {
    if (!GetIt.I.isRegistered<OfflineCubit>()) return null;
    return GetIt.I<OfflineCubit>();
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

  @override
  Future<void> close() {
    _clearPendingTrackSwitch();
    _prefetchedIds.clear();
    _subscription?.cancel();
    return super.close();
  }
}
