enum TrackStatus {
  PROCESSING,
  FINISHED,
  FAILED;

  static TrackStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'FINISHED':
        return TrackStatus.FINISHED;
      case 'FAILED':
        return TrackStatus.FAILED;
      case 'PROCESSING':
      default:
        return TrackStatus.PROCESSING;
    }
  }

  bool get isTerminal => this == FINISHED || this == FAILED;
  bool get isReady => this == FINISHED;
  bool get isProcessing => this == PROCESSING;
}
