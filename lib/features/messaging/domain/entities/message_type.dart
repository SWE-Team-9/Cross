enum MessageType {
  text,
  trackShare,
  playlistShare,
  unknown,
}

extension MessageTypeX on MessageType {
  static MessageType fromApi(dynamic raw) {
    final normalized = raw?.toString().trim().toUpperCase() ?? '';

    switch (normalized) {
      case 'TEXT':
        return MessageType.text;
      case 'TRACK_SHARE':
        return MessageType.trackShare;
      case 'PLAYLIST_SHARE':
        return MessageType.playlistShare;
      default:
        return MessageType.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case MessageType.text:
        return 'TEXT';
      case MessageType.trackShare:
        return 'TRACK_SHARE';
      case MessageType.playlistShare:
        return 'PLAYLIST_SHARE';
      case MessageType.unknown:
        return 'UNKNOWN';
    }
  }

  bool get isShare =>
      this == MessageType.trackShare || this == MessageType.playlistShare;
}
