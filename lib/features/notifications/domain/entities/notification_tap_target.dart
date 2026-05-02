import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';

sealed class NotificationTapTarget {
  const NotificationTapTarget();
}

final class NotificationCommentsTapTarget extends NotificationTapTarget {
  const NotificationCommentsTapTarget({required this.trackId});

  final String trackId;
}

final class NotificationConversationTapTarget extends NotificationTapTarget {
  const NotificationConversationTapTarget({required this.conversation});

  final ConversationEntity conversation;
}

final class NotificationProfileTapTarget extends NotificationTapTarget {
  const NotificationProfileTapTarget({required this.handle});

  final String handle;
}