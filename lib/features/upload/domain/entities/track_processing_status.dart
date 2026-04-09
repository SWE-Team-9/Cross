import 'package:equatable/equatable.dart';

import 'track_status.dart';

class TrackProcessingStatus extends Equatable {
  const TrackProcessingStatus({
    required this.trackId,
    required this.status,
  });

  final String trackId;
  final TrackStatus status;

  bool get isTerminal => status.isTerminal;
  bool get isReady => status.isReady;
  bool get isProcessing => status.isProcessing;

  @override
  List<Object?> get props => [trackId, status];
}
