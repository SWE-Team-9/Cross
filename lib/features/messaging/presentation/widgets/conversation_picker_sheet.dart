import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/platform_url_utils.dart';
import '../../domain/entities/conversation_entity.dart';
import '../bloc/share_track_to_conversation_cubit.dart';
import '../bloc/share_track_to_conversation_state.dart';
import '../messaging_theme.dart';

class ConversationPickerSheet extends StatefulWidget {
  final String title;
  final String actionLabel;
  final Future<void> Function(ConversationEntity conversation)
      onConversationSelected;

  const ConversationPickerSheet({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onConversationSelected,
  });

  @override
  State<ConversationPickerSheet> createState() =>
      _ConversationPickerSheetState();
}

class _ConversationPickerSheetState extends State<ConversationPickerSheet> {
  final ScrollController _scrollController = ScrollController();
  bool _isHandlingSelection = false;

  @override
  void initState() {
    super.initState();
    context.read<ShareTrackToConversationCubit>().loadInitial();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      context.read<ShareTrackToConversationCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSelect(ConversationEntity conversation) async {
    if (_isHandlingSelection) return;

    setState(() => _isHandlingSelection = true);

    try {
      await widget.onConversationSelected(conversation);
    } finally {
      if (mounted) {
        setState(() => _isHandlingSelection = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShareTrackToConversationCubit,
        ShareTrackToConversationState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: MessagingTheme.surfaceAlt,
              content: Text(state.successMessage!),
            ),
          );
        }

        if (state.errorMessage != null && !state.isLoadingConversations) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF2B2B2B),
              content: Text(state.errorMessage!),
            ),
          );
        }
      },
      builder: (context, state) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            decoration: const BoxDecoration(
              color: MessagingTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: MessagingTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: _buildBody(state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(ShareTrackToConversationState state) {
    if (state.isLoadingConversations && state.conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: MessagingTheme.accent),
      );
    }

    if (state.conversations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No conversations yet',
            textAlign: TextAlign.center,
            style: TextStyle(color: MessagingTheme.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      itemCount: state.conversations.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == state.conversations.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: MessagingTheme.accent,
                  strokeWidth: 2.2,
                ),
              ),
            ),
          );
        }

        final conversation = state.conversations[index];
        final isSelected =
            state.selectedConversationId == conversation.conversationId;
        final avatarUrl = PlatformUrlUtils.normalizeBackendUrl(
          conversation.participant.avatarUrl,
        );

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: state.isSharing || _isHandlingSelection
              ? null
              : () => _handleSelect(conversation),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MessagingTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected ? MessagingTheme.accent : MessagingTheme.border,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF262626),
                  foregroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: Text(
                    conversation.participant.displayName.isNotEmpty
                        ? conversation.participant.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.participant.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MessagingTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${conversation.participant.handle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MessagingTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (state.isSharing && isSelected)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: MessagingTheme.accent,
                      strokeWidth: 2.2,
                    ),
                  )
                else
                  Text(
                    widget.actionLabel,
                    style: const TextStyle(
                      color: MessagingTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
