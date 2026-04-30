import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/get_conversation_meta_usecase.dart';
import '../messaging_theme.dart';
import 'chat_thread_page.dart';

class ChatThreadLoaderPage extends StatefulWidget {
  final String conversationId;

  const ChatThreadLoaderPage({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatThreadLoaderPage> createState() => _ChatThreadLoaderPageState();
}

class _ChatThreadLoaderPageState extends State<ChatThreadLoaderPage> {
  late final Future<ConversationEntity> _future;

  @override
  void initState() {
    super.initState();
    _future = GetIt.I<GetConversationMetaUseCase>()(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConversationEntity>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: MessagingTheme.background,
            body: Center(
              child: CircularProgressIndicator(
                color: MessagingTheme.accent,
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: MessagingTheme.background,
            appBar: AppBar(
              backgroundColor: MessagingTheme.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Conversation',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error?.toString() ?? 'Conversation not found',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          );
        }

        final conversation = snapshot.data!;

        return ChatThreadPage(
          conversationId: conversation.conversationId,
          receiverId: conversation.participant.id,
          participantDisplayName: conversation.participant.displayName,
          participantHandle: conversation.participant.handle,
          participantAvatarUrl: conversation.participant.avatarUrl,
          canMessage: conversation.canMessage,
          blockReason: conversation.blockReason,
        );
      },
    );
  }
}
