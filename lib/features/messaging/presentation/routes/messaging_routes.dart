import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/conversation_entity.dart';

abstract class MessagingRoutes {
  static const String inbox = '/messages';
  static const String chatThread = '/messages/:conversationId';

  static void goToInbox(BuildContext context) {
    context.push(inbox);
  }

  static void goToConversation(
    BuildContext context,
    ConversationEntity conversation,
  ) {
    context.push(
      '/messages/${conversation.conversationId}',
      extra: conversation,
    );
  }

  static void goToConversationById(
    BuildContext context,
    String conversationId,
  ) {
    context.push('/messages/$conversationId');
  }
}