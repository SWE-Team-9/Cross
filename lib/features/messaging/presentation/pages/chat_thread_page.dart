import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';

import '../../../../core/utils/platform_url_utils.dart';
import '../../domain/usecases/connect_messaging_socket_usecase.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
import '../../domain/usecases/delete_message_usecase.dart';
import '../../domain/usecases/get_conversation_messages_usecase.dart';
import '../../domain/usecases/mark_conversation_read_usecase.dart';
import '../../domain/usecases/send_text_message_usecase.dart';
import '../../domain/usecases/share_playlist_message_usecase.dart';
import '../../domain/usecases/share_track_message_usecase.dart';
import '../bloc/chat_thread_cubit.dart';
import '../bloc/chat_thread_state.dart';
import '../messaging_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_composer.dart';
import '../widgets/share_message_item_sheet.dart';

class ChatThreadPage extends StatelessWidget {
  final String conversationId;
  final String receiverId;
  final String participantDisplayName;
  final String participantHandle;
  final String? participantAvatarUrl;
  final bool canMessage;
  final String? blockReason;
  final VoidCallback? onBack;

  const ChatThreadPage({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.participantDisplayName,
    required this.participantHandle,
    required this.participantAvatarUrl,
    this.canMessage = true,
    this.blockReason,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final authState = _authStateOf(context);
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : null;

    return BlocProvider(
      create: (_) => ChatThreadCubit(
        getConversationMessagesUseCase:
            GetIt.I<GetConversationMessagesUseCase>(),
        sendTextMessageUseCase: GetIt.I<SendTextMessageUseCase>(),
        markConversationReadUseCase: GetIt.I<MarkConversationReadUseCase>(),
        deleteConversationUseCase: GetIt.I<DeleteConversationUseCase>(),
        deleteMessageUseCase: GetIt.I<DeleteMessageUseCase>(),
        connectMessagingSocketUseCase: GetIt.I<ConnectMessagingSocketUseCase>(),
        shareTrackMessageUseCase: _getItOrNull<ShareTrackMessageUseCase>(),
        sharePlaylistMessageUseCase:
            _getItOrNull<SharePlaylistMessageUseCase>(),
      )..load(
          conversationId: conversationId,
          receiverId: receiverId,
          currentUserId: currentUserId,
          canMessage: canMessage,
        ),
      child: _ChatThreadView(
        conversationId: conversationId,
        receiverId: receiverId,
        participantDisplayName: participantDisplayName,
        participantHandle: participantHandle,
        participantAvatarUrl: participantAvatarUrl,
        canMessage: canMessage,
        blockReason: blockReason,
        onBack: onBack,
      ),
    );
  }

  AuthState? _authStateOf(BuildContext context) {
    try {
      return context.read<AuthCubit>().state;
    } catch (_) {
      final getIt = GetIt.I;
      if (getIt.isRegistered<AuthCubit>()) {
        return getIt<AuthCubit>().state;
      }
      return null;
    }
  }

  T? _getItOrNull<T extends Object>() {
    final getIt = GetIt.I;
    return getIt.isRegistered<T>() ? getIt<T>() : null;
  }
}

class _ChatThreadView extends StatefulWidget {
  final String conversationId;
  final String receiverId;
  final String participantDisplayName;
  final String participantHandle;
  final String? participantAvatarUrl;
  final bool canMessage;
  final String? blockReason;
  final VoidCallback? onBack;

  const _ChatThreadView({
    required this.conversationId,
    required this.receiverId,
    required this.participantDisplayName,
    required this.participantHandle,
    required this.participantAvatarUrl,
    required this.canMessage,
    required this.blockReason,
    required this.onBack,
  });

  @override
  State<_ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<_ChatThreadView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 120) {
      context.read<ChatThreadCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String? _currentUserId(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  Future<void> _openShareSheet() async {
    await ShareMessageItemSheet.show(
      context,
      onShareTrack: (track) =>
          context.read<ChatThreadCubit>().shareTrack(track.id),
      onSharePlaylist: (playlist) =>
          context.read<ChatThreadCubit>().sharePlaylist(playlist.playlistId),
    );
  }

  void _openParticipantProfile() {
    final handle = widget.participantHandle.trim().replaceFirst('@', '');
    if (handle.isEmpty) return;
    context.push('/profile/$handle');
  }

  Future<void> _confirmDeleteConversation() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF1B1B1B),
            title: const Text(
              'Delete conversation?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'This will remove the conversation for you.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await context.read<ChatThreadCubit>().deleteConversation();
    if (!mounted) return;

    if (widget.onBack != null) {
      widget.onBack!.call();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        PlatformUrlUtils.normalizeBackendUrl(widget.participantAvatarUrl);

    return Scaffold(
      backgroundColor: MessagingTheme.background,
      appBar: AppBar(
        backgroundColor: MessagingTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!.call();
              return;
            }
            Navigator.maybePop(context);
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _openParticipantProfile,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: MessagingTheme.surface,
                foregroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: Text(
                  widget.participantDisplayName.isNotEmpty
                      ? widget.participantDisplayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.participantDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${widget.participantHandle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<ChatThreadCubit, ChatThreadState>(
            builder: (context, state) {
              return PopupMenuButton<String>(
                color: const Color(0xFF1B1B1B),
                icon: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: state.isSocketConnected
                          ? Colors.greenAccent
                          : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDeleteConversation();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Delete conversation',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatThreadCubit, ChatThreadState>(
              listener: (context, state) {
                if (state.errorMessage != null && state.messages.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF2B2B2B),
                      content: Text(state.errorMessage!),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.isLoading && state.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: MessagingTheme.accent,
                    ),
                  );
                }

                if (state.errorMessage != null && state.messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sms_failed_outlined,
                            color: Colors.white24,
                            size: 54,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () =>
                                context.read<ChatThreadCubit>().load(
                                      conversationId: widget.conversationId,
                                      receiverId: widget.receiverId,
                                      canMessage: widget.canMessage,
                                    ),
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

                if (state.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Start the conversation',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final currentUserId = _currentUserId(context);

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  itemCount:
                      state.messages.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (state.isLoadingMore && index == state.messages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: MessagingTheme.accent,
                            strokeWidth: 2.4,
                          ),
                        ),
                      );
                    }

                    final message =
                        state.messages[state.messages.length - 1 - index];

                    final isMine = currentUserId != null &&
                        message.senderId == currentUserId;

                    return MessageBubble(
                      message: message,
                      isMine: isMine,
                      onDelete: isMine
                          ? () => context
                              .read<ChatThreadCubit>()
                              .deleteMessage(message.id)
                          : null,
                      onTrackTap: message.sharedTrack == null
                          ? null
                          : () {
                              final track = message.sharedTrack!;
                              if (track.handle != null &&
                                  track.handle!.isNotEmpty &&
                                  track.slug != null &&
                                  track.slug!.isNotEmpty) {
                                context.pushNamed(
                                  'resolve-handle-slug',
                                  pathParameters: {
                                    'handle': track.handle!,
                                    'slug': track.slug!,
                                  },
                                );
                              } else {
                                context.pushNamed(
                                  'track-detail',
                                  pathParameters: {
                                    'trackId': track.id,
                                  },
                                );
                              }
                            },
                      onPlaylistTap: message.sharedPlaylist == null
                          ? null
                          : () => context.push(
                                '/playlist/${message.sharedPlaylist!.id}',
                              ),
                    );
                  },
                );
              },
            ),
          ),
          if (!widget.canMessage)
            _MessagingBlockedBanner(
              reason: widget.blockReason,
            )
          else
            BlocBuilder<ChatThreadCubit, ChatThreadState>(
              builder: (context, state) {
                return MessageComposer(
                  isSending: state.isSending,
                  onAttach: _openShareSheet,
                  onSend: (text) {
                    context.read<ChatThreadCubit>().sendText(text);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MessagingBlockedBanner extends StatelessWidget {
  final String? reason;

  const _MessagingBlockedBanner({
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final message = (reason ?? '').trim().isNotEmpty
        ? reason!.trim()
        : 'You cannot message this user.';

    return Container(
      width: double.infinity,
      color: MessagingTheme.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: MessagingTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.block,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}