import 'package:equatable/equatable.dart';

import 'track_status.dart';

abstract class TrackProcessingState extends Equatable {
  const TrackProcessingState();

  @override
  List<Object?> get props => [];
}

/// No track is being watched.
class TrackProcessingIdle extends TrackProcessingState {
  const TrackProcessingIdle();
}

/// Actively polling — [trackId] is the track being watched.
class TrackProcessingInProgress extends TrackProcessingState {
  const TrackProcessingInProgress({
    required this.trackId,
    this.pollAttempt = 0,
  });

  final String trackId;
  final int pollAttempt;

  @override
  List<Object?> get props => [trackId, pollAttempt];
}

/// Backend returned FINISHED for [trackId].
class TrackProcessingReady extends TrackProcessingState {
  const TrackProcessingReady({required this.trackId});

  final String trackId;

  @override
  List<Object?> get props => [trackId];
}

/// Backend returned FAILED, max attempts exceeded, or a network error occurred.
class TrackProcessingFailed extends TrackProcessingState {
  const TrackProcessingFailed({
    required this.trackId,
    this.reason,
  });

  final String trackId;
  final String? reason;

  @override
  List<Object?> get props => [trackId, reason];
}

extension TrackProcessingStateX on TrackProcessingState {
  bool get isIdle => this is TrackProcessingIdle;
  bool get isInProgress => this is TrackProcessingInProgress;
  bool get isReady => this is TrackProcessingReady;
  bool get isFailed => this is TrackProcessingFailed;

  String? get trackId => switch (this) {
        final TrackProcessingInProgress s => s.trackId,
        final TrackProcessingReady s => s.trackId,
        final TrackProcessingFailed s => s.trackId,
        _ => null,
      };

  TrackStatus? get asTrackStatus => switch (this) {
        TrackProcessingInProgress() => TrackStatus.PROCESSING,
        TrackProcessingReady() => TrackStatus.FINISHED,
        TrackProcessingFailed() => TrackStatus.FAILED,
        _ => null,
      };
}
