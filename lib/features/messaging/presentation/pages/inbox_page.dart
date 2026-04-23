import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MessagingTheme.background,
      appBar: AppBar(
        backgroundColor: MessagingTheme.background,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: BlocBuilder<InboxCubit, InboxState>(
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      color: Colors.white24,
                      size: 56,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No conversations yet',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'When you start chatting with someone, it will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38),
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

                return ConversationTile(
                  conversation: conversation,
                  onTap: () => widget.onOpenConversation(conversation),
                );
              },
            ),
          );
        },
      ),
    );
  }
}