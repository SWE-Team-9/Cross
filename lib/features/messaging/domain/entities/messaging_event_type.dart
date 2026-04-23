enum MessagingEventType {
  newMessage,
  unknown,
}

extension MessagingEventTypeX on MessagingEventType {
  static MessagingEventType fromApi(dynamic raw) {
    final normalized = raw?.toString().trim().toUpperCase() ?? '';

    switch (normalized) {
      case 'NEW_MESSAGE':
        return MessagingEventType.newMessage;
      default:
        return MessagingEventType.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case MessagingEventType.newMessage:
        return 'NEW_MESSAGE';
      case MessagingEventType.unknown:
        return 'UNKNOWN';
    }
  }
}