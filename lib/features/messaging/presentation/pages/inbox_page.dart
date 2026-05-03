import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/archive_conversation_usecase.dart';
import '../../domain/usecases/connect_messaging_socket_usecase.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/mark_conversation_read_usecase.dart';
import '../../domain/usecases/mark_conversation_unread_usecase.dart';
import '../../domain/usecases/unarchive_conversation_usecase.dart';
import '../bloc/inbox_cubit.dart';
import '../bloc/inbox_state.dart';
import '../messaging_theme.dart';
import '../widgets/conversation_tile.dart';

class InboxPage extends StatelessWidget {
  final Future<void> Function(ConversationEntity conversation)
      onOpenConversation;

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
        markConversationUnreadUseCase: GetIt.I<MarkConversationUnreadUseCase>(),
        archiveConversationUseCase: GetIt.I<ArchiveConversationUseCase>(),
        unarchiveConversationUseCase: GetIt.I<UnarchiveConversationUseCase>(),
        deleteConversationUseCase: GetIt.I<DeleteConversationUseCase>(),
        connectMessagingSocketUseCase: GetIt.I<ConnectMessagingSocketUseCase>(),
      )..loadInitial(),
      child: _InboxView(onOpenConversation: onOpenConversation),
    );
  }
}

class _InboxView extends StatefulWidget {
  final Future<void> Function(ConversationEntity conversation)
      onOpenConversation;

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

  Future<void> _openConversationAsRead(
    BuildContext context,
    ConversationEntity conversation,
  ) async {
    final inboxCubit = context.read<InboxCubit>();

    await inboxCubit.markConversationAsRead(
      conversation.conversationId,
    );

    await widget.onOpenConversation(conversation);

    if (!mounted) return;
    await inboxCubit.refresh();
  }

  void _showConversationActions(
    BuildContext context,
    ConversationEntity conversation,
  ) {
    final inboxCubit = context.read<InboxCubit>();
    final isArchivedMode = inboxCubit.state.isArchivedMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Mark as read',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        conversation.participant.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4), 
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        inboxCubit.markConversationAsRead(
                          conversation.conversationId,
                        );
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Mark as unread',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
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
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.archive_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Archive conversation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          inboxCubit.archiveConversation(
                            conversation.conversationId,
                          );
                        },
                      )
                    else
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.unarchive_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Unarchive conversation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          inboxCubit.unarchiveConversation(
                            conversation.conversationId,
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              elevation: 0,
              scrolledUnderElevation: 0,
              title: BlocBuilder<InboxCubit, InboxState>(
                builder: (context, state) {
                  return Text(
                    state.isArchivedMode ? 'Archived' : 'Messages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  );
                },
              ),
              actions: [
                BlocBuilder<InboxCubit, InboxState>(
                  builder: (context, state) {
                    return Center(
                      child: IconButton(
                        tooltip: 'Refresh',
                        onPressed: state.isLoading || state.isRefreshing
                            ? null
                            : () => context.read<InboxCubit>().refresh(),
                        icon: state.isRefreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: MessagingTheme.accent,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh, color: Colors.white70, size: 22),
                      ),
                    );
                  },
                ),
                BlocBuilder<InboxCubit, InboxState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => context.read<InboxCubit>().toggleArchivedMode(),
                        icon: Icon(
                          state.isArchivedMode
                              ? Icons.inbox_outlined
                              : Icons.archive_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        label: Text(
                          state.isArchivedMode ? 'Inbox' : 'Archived',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ambient backlights
          Positioned(
            top: -50,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MessagingTheme.accent.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00FFCC).withValues(alpha: 0.06),
                ),
              ),
            ),
          ),

          // Main Conversation List
          BlocConsumer<InboxCubit, InboxState>(
            listener: (context, state) {
              if (state.errorMessage != null && state.conversations.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    elevation: 0,
                    margin: const EdgeInsets.all(16),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    content: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state.isLoading && state.conversations.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: MessagingTheme.accent,
                    strokeWidth: 2,
                  ),
                );
              }

              if (state.errorMessage != null && state.conversations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                          onPressed: () => context.read<InboxCubit>().loadInitial(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.conversations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          state.isArchivedMode
                              ? Icons.archive_outlined
                              : Icons.chat_bubble_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 52,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.isArchivedMode
                              ? 'No archived conversations'
                              : 'Your inbox is empty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.isArchivedMode
                              ? 'Archived messages will show up here.'
                              : 'Direct messages you start on SoundCloud will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: MessagingTheme.accent,
                backgroundColor: Colors.black,
                strokeWidth: 2,
                edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
                onRefresh: () => context.read<InboxCubit>().refresh(),
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                    16,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  itemCount:
                      state.conversations.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == state.conversations.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: MessagingTheme.accent,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    final conversation = state.conversations[index];

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: GestureDetector(
                            onLongPress: () => _showConversationActions(
                              context,
                              conversation,
                            ),
                            child: ConversationTile(
                              conversation: conversation,
                              onTap: () {
                                _openConversationAsRead(
                                  context,
                                  conversation,
                                );
                              },
                              onMorePressed: () => _showConversationActions(
                                context,
                                conversation,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}