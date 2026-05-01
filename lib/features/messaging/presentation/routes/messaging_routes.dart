import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/conversation_entity.dart';

abstract class MessagingRoutes {
  static const String inbox = '/messages';
  static const String chatThread = '/messages/:conversationId';

  static void goToInbox(BuildContext context) {
    context.push(inbox);
  }

  static Future<T?> goToConversation<T>(
    BuildContext context,
    ConversationEntity conversation,
  ) {
    return context.push<T>(
      '/messages/${conversation.conversationId}',
      extra: conversation,
    );
  }

  static Future<T?> goToConversationById<T>(
    BuildContext context,
    String conversationId,
  ) {
    return context.push<T>('/messages/$conversationId');
  }
}
