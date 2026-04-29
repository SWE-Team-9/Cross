import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/archive_conversation_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/mark_conversation_read_usecase.dart';
import '../../domain/usecases/mark_conversation_unread_usecase.dart';
import '../../domain/usecases/unarchive_conversation_usecase.dart';
import '../bloc/inbox_cubit.dart';
import '../bloc/inbox_state.dart';
import '../messaging_theme.dart';
import '../widgets/conversation_tile.dart';

class InboxPage extends StatelessWidget {
  final ValueChanged<ConversationEntity> onOpenConversation;

  const InboxPage({
    super.key,
    required this.onOpenConversation,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InboxCubit(
        getConversationsUseCase: GetIt.I<GetConversationsUseCase>(),
        markConversationReadUseCase: GetIt.I<MarkConversationReadUseCase>(),
        markConversationUnreadUseCase:
            GetIt.I<MarkConversationUnreadUseCase>(),
        archiveConversationUseCase: GetIt.I<ArchiveConversationUseCase>(),
        unarchiveConversationUseCase: GetIt.I<UnarchiveConversationUseCase>(),
      )..loadInitial(),
      child: _InboxView(onOpenConversation: onOpenConversation),
    );
  }
}

class _InboxView extends StatefulWidget {
  final ValueChanged<ConversationEntity> onOpenConversation;

  const _InboxView({
    required this.onOpenConversation,
  });

  @override
  State<_InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<_InboxView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      context.read<InboxCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showConversationActions(
    BuildContext context,
    ConversationEntity conversation,
  ) {
    final inboxCubit = context.read<InboxCubit>();
    final isArchivedMode = inboxCubit.state.isArchivedMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: MessagingTheme.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Mark as read',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  conversation.participant.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  inboxCubit.markConversationAsRead(
                    conversation.conversationId,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Mark as unread',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  inboxCubit.markConversationAsUnread(
                    conversation.conversationId,
                  );
                },
              ),
              if (!isArchivedMode)
                ListTile(
                  leading: const Icon(
                    Icons.archive_outlined,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Archive conversation',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    inboxCubit.archiveConversation(
                      conversation.conversationId,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF2B2B2B),
                        content: Text('Conversation archived'),
                      ),
                    );
                  },
                )
              else
                ListTile(
                  leading: const Icon(
                    Icons.unarchive_outlined,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Unarchive conversation',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    inboxCubit.unarchiveConversation(
                      conversation.conversationId,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF2B2B2B),
                        content: Text('Conversation unarchived'),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MessagingTheme.background,
      appBar: AppBar(
        backgroundColor: MessagingTheme.background,
        elevation: 0,
        title: BlocBuilder<InboxCubit, InboxState>(
          builder: (context, state) {
            return Text(
              state.isArchivedMode ? 'Archived Messages' : 'Messages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            );
          },
        ),
        actions: [
          BlocBuilder<InboxCubit, InboxState>(
            builder: (context, state) {
              return TextButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => context.read<InboxCubit>().toggleArchivedMode(),
                icon: Icon(
                  state.isArchivedMode
                      ? Icons.inbox_outlined
                      : Icons.archive_outlined,
                  color: Colors.white70,
                  size: 18,
                ),
                label: Text(
                  state.isArchivedMode ? 'Inbox' : 'Archived',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BlocConsumer<InboxCubit, InboxState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.conversations.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF2B2B2B),
                content: Text(state.errorMessage!),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.conversations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: MessagingTheme.accent),
            );
          }

          if (state.errorMessage != null && state.conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_chat_unread_outlined,
                      color: Colors.white24,
                      size: 54,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => context.read<InboxCubit>().loadInitial(),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: MessagingTheme.accent),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isArchivedMode
                          ? Icons.archive_outlined
                          : Icons.forum_outlined,
                      color: Colors.white24,
                      size: 56,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      state.isArchivedMode
                          ? 'No archived conversations'
                          : 'No conversations yet',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.isArchivedMode
                          ? 'Archived chats will appear here.'
                          : 'When you start chatting with someone, it will show up here.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: MessagingTheme.accent,
            backgroundColor: MessagingTheme.surface,
            onRefresh: () => context.read<InboxCubit>().refresh(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount:
                  state.conversations.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == state.conversations.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: MessagingTheme.accent,
                        strokeWidth: 2.5,
                      ),
                    ),
                  );
                }

                final conversation = state.conversations[index];

                return GestureDetector(
                  onLongPress: () => _showConversationActions(
                    context,
                    conversation,
                  ),
                  child: ConversationTile(
                    conversation: conversation,
                    onTap: () => widget.onOpenConversation(conversation),
                    onMorePressed: () => _showConversationActions(
                      context,
                      conversation,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}