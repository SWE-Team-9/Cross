enum TrackManagementVisibility {
  publicTrack,
  privateTrack,
}

extension TrackManagementVisibilityX on TrackManagementVisibility {
  String get apiValue {
    switch (this) {
      case TrackManagementVisibility.publicTrack:
        return 'PUBLIC';
      case TrackManagementVisibility.privateTrack:
        return 'PRIVATE';
    }
  }

  String get displayLabel {
    switch (this) {
      case TrackManagementVisibility.publicTrack:
        return 'Public';
      case TrackManagementVisibility.privateTrack:
        return 'Private';
    }
  }
}

TrackManagementVisibility trackManagementVisibilityFromApiValue(
  String? value,
) {
  switch ((value ?? '').toUpperCase()) {
    case 'PRIVATE':
      return TrackManagementVisibility.privateTrack;
    case 'PUBLIC':
    default:
      return TrackManagementVisibility.publicTrack;
  }
}
