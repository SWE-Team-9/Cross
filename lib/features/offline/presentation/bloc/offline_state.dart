class OfflineState {
  final Map<String, String> downloadedTracks;

  const OfflineState({
    this.downloadedTracks = const {},
  });

  OfflineState copyWith({
    Map<String, String>? downloadedTracks,
  }) {
    return OfflineState(
      downloadedTracks: downloadedTracks ?? this.downloadedTracks,
    );
  }
}
