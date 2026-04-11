import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/track_status.dart';
import '../../domain/entities/track_processing_state.dart';
import '../../domain/usecases/watch_track_processing_status_use_case.dart';
//
//Eyad Notes : Workflow for track processing status:
/// Shared singleton cubit consumed by:
///   - Upload screen        → starts watching after 202 response
///   - Creator tracks list  → shows per-track processing badge (T3.10)
///   - Player entry points  → gates playback until track is FINISHED (T3.11)
///
/// Registered as @lazySingleton so all screens share one instance via get_it.
/// Holds an internal map of trackId → state so multiple tracks can be polled
/// simultaneously (e.g. creator list with several PROCESSING tracks).
class TrackProcessingCubit extends Cubit<TrackProcessingState> {
  TrackProcessingCubit(this._watchStatus) : super(const TrackProcessingIdle());

  final WatchTrackProcessingStatusUseCase _watchStatus;

  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};
  final Map<String, TrackProcessingState> _trackStates = {};

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Start polling for [trackId].
  /// Safe to call multiple times — cancels any existing subscription first.
  void startWatching(String trackId) {
    _cancelSubscription(trackId);

    final initial = TrackProcessingInProgress(trackId: trackId);
    _trackStates[trackId] = initial;
    emit(initial);

    int attempt = 0;

    _subscriptions[trackId] = _watchStatus(trackId).listen(
      (status) {
        attempt++;
        final TrackProcessingState next = switch (status.status) {
          TrackStatus.PROCESSING => TrackProcessingInProgress(
              trackId: trackId,
              pollAttempt: attempt,
            ),
          TrackStatus.FINISHED => TrackProcessingReady(trackId: trackId),
          TrackStatus.FAILED => TrackProcessingFailed(trackId: trackId),
        };

        _trackStates[trackId] = next;
        emit(next);

        if (status.isTerminal) _cancelSubscription(trackId);
      },
      onError: (_) {
        final failed = TrackProcessingFailed(
          trackId: trackId,
          reason: 'Stream error',
        );
        _trackStates[trackId] = failed;
        emit(failed);
        _cancelSubscription(trackId);
      },
    );
  }

  /// Stop watching a specific track (e.g. user navigates away mid-upload).
  void stopWatching(String trackId) {
    _cancelSubscription(trackId);
    _trackStates.remove(trackId);
  }

  /// Stop all polling and reset to idle.
  void stopAll() {
    for (final id in _subscriptions.keys.toList()) {
      _cancelSubscription(id);
    }
    _trackStates.clear();
    emit(const TrackProcessingIdle());
  }

  /// Read the cached state for any [trackId].
  /// Returns [TrackProcessingIdle] if the track is not being watched.
  /// Use this in creator list rows to get per-track state without
  /// rebuilding the entire list on every poll.
  TrackProcessingState stateForTrack(String trackId) {
    return _trackStates[trackId] ?? const TrackProcessingIdle();
  }

  bool get hasActivePolling => _subscriptions.isNotEmpty;

  // ─── Private ───────────────────────────────────────────────────────────────

  void _cancelSubscription(String trackId) {
    _subscriptions[trackId]?.cancel();
    _subscriptions.remove(trackId);
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    return super.close();
  }
}
