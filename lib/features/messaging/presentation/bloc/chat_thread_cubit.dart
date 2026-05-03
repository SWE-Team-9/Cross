import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_type.dart';
import '../../domain/entities/realtime_message_event_entity.dart';
import '../../domain/usecases/connect_messaging_socket_usecase.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
import '../../domain/usecases/delete_message_usecase.dart';
import '../../domain/usecases/get_conversation_messages_usecase.dart';
import '../../domain/usecases/mark_conversation_read_usecase.dart';
import '../../domain/usecases/send_text_message_usecase.dart';
import '../../domain/usecases/share_playlist_message_usecase.dart';
import '../../domain/usecases/share_track_message_usecase.dart';
import 'chat_thread_state.dart';

class ChatThreadCubit extends Cubit<ChatThreadState> {
  final GetConversationMessagesUseCase getConversationMessagesUseCase;
  final SendTextMessageUseCase sendTextMessageUseCase;
  final MarkConversationReadUseCase markConversationReadUseCase;
  final DeleteConversationUseCase deleteConversationUseCase;
  final DeleteMessageUseCase deleteMessageUseCase;
  final ConnectMessagingSocketUseCase connectMessagingSocketUseCase;
  final ShareTrackMessageUseCase? shareTrackMessageUseCase;
  final SharePlaylistMessageUseCase? sharePlaylistMessageUseCase;

  StreamSubscription<RealtimeMessageEventEntity>? _socketSub;

  String? _conversationId;
  String? _receiverId;
  String? _currentUserId;
  bool _canMessage = true;

  ChatThreadCubit({
    required this.getConversationMessagesUseCase,
    required this.sendTextMessageUseCase,
    required this.markConversationReadUseCase,
    required this.deleteConversationUseCase,
    required this.deleteMessageUseCase,
    required this.connectMessagingSocketUseCase,
    this.shareTrackMessageUseCase,
    this.sharePlaylistMessageUseCase,
  }) : super(ChatThreadState.initial());

  Future<void> load({
    required String conversationId,
    required String receiverId,
    String? currentUserId,
    bool canMessage = true,
  }) async {
    _conversationId = conversationId;
    _receiverId = receiverId;
    _currentUserId = currentUserId;
    _canMessage = canMessage;

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        messages: const [],
        page: 1,
        hasMore: true,
      ),
    );

    try {
      final pageData = await getConversationMessagesUseCase(
        conversationId,
        page: 1,
        limit: 50,
      );

      final sorted = _sortMessages(pageData.messages);

      emit(
        state.copyWith(
          isLoading: false,
          messages: sorted,
          page: pageData.page,
          hasMore: pageData.hasMore,
          clearError: true,
        ),
      );

      await markCurrentConversationAsRead();
      await _connectSocket();
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final conversationId = _conversationId;
    if (conversationId == null ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final nextPage = state.page + 1;
      final pageData = await getConversationMessagesUseCase(
        conversationId,
        page: nextPage,
        limit: 50,
      );

      final merged = _sortMessages([
        ...state.messages,
        ...pageData.messages,
      ]);

      emit(
        state.copyWith(
          isLoadingMore: false,
          messages: merged,
          page: pageData.page,
          hasMore: pageData.hasMore,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> sendText(String text) async {
    if (!_canMessage) {
      emit(state.copyWith(errorMessage: 'You cannot message this user.'));
      return;
    }

    final receiverId = _receiverId;
    if (receiverId == null) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final tempMessage = _optimisticTextMessage(trimmed);

    emit(
      state.copyWith(
        isSending: true,
        messages: _sortMessages([...state.messages, tempMessage]),
        clearError: true,
      ),
    );

    try {
      final message = await sendTextMessageUseCase(
        receiverId: receiverId,
        text: trimmed,
      );
      final normalized = _normalizeSentMessage(
        message,
        fallback: tempMessage,
      );

      emit(
        state.copyWith(
          isSending: false,
          messages: _replaceMessage(tempMessage.id, normalized),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSending: false,
          messages: _removeMessage(tempMessage.id),
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> shareTrack(String trackId, {String? text}) async {
    if (!_canMessage) {
      emit(state.copyWith(errorMessage: 'You cannot message this user.'));
      return;
    }

    final receiverId = _receiverId;
    if (receiverId == null || trackId.trim().isEmpty) return;
    final shareTrack = shareTrackMessageUseCase;
    if (shareTrack == null) {
      emit(
        state.copyWith(
          errorMessage: 'Track sharing is not available right now.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSending: true, clearError: true));

    try {
      final message = await shareTrack(
        receiverId: receiverId,
        trackId: trackId.trim(),
        text: text,
      );
      _appendSentMessage(message);
    } catch (e) {
      emit(state.copyWith(isSending: false, errorMessage: e.toString()));
    }
  }

  Future<void> sharePlaylist(String playlistId, {String? text}) async {
    if (!_canMessage) {
      emit(state.copyWith(errorMessage: 'You cannot message this user.'));
      return;
    }

    final receiverId = _receiverId;
    if (receiverId == null || playlistId.trim().isEmpty) return;
    final sharePlaylist = sharePlaylistMessageUseCase;
    if (sharePlaylist == null) {
      emit(
        state.copyWith(
          errorMessage: 'Playlist sharing is not available right now.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSending: true, clearError: true));

    try {
      final message = await sharePlaylist(
        receiverId: receiverId,
        playlistId: playlistId.trim(),
        text: text,
      );
      _appendSentMessage(message);
    } catch (e) {
      emit(state.copyWith(isSending: false, errorMessage: e.toString()));
    }
  }

  Future<void> deleteMessage(String messageId) async {
    MessageEntity? existing;
    for (final message in state.messages) {
      if (message.id == messageId) {
        existing = message;
        break;
      }
    }

    if (existing?.isDeleted == true) {
      emit(
        state.copyWith(
          messages: _removeMessage(messageId),
          clearError: true,
        ),
      );
      return;
    }

    try {
      await deleteMessageUseCase(messageId);

      emit(
        state.copyWith(
          messages: state.messages.map((message) {
            return message.id == messageId ? _deletedMessage(message) : message;
          }).toList(growable: false),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> deleteConversation() async {
    final conversationId = _conversationId;
    if (conversationId == null || conversationId.isEmpty) return;
    final targetMessageId = state.messages.isNotEmpty
        ? state.messages.last.id
        : conversationId;

    try {
      await deleteConversationUseCase(targetMessageId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> markCurrentConversationAsRead() async {
    final conversationId = _conversationId;
    if (conversationId == null || conversationId.isEmpty) return;

    try {
      await markConversationReadUseCase(conversationId);
    } catch (_) {
      // Do not block opening or using the chat if marking as read fails.
    }
  }

  Future<void> _connectSocket() async {
    try {
      await connectMessagingSocketUseCase();

      await _socketSub?.cancel();
      _socketSub = connectMessagingSocketUseCase.eventsStream.listen(
        _handleSocketEvent,
        onError: (Object error) {
          emit(
            state.copyWith(
              isSocketConnected: false,
              errorMessage: error.toString(),
            ),
          );
        },
      );

      emit(state.copyWith(isSocketConnected: true));
    } catch (e) {
      emit(
        state.copyWith(
          isSocketConnected: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _handleSocketEvent(RealtimeMessageEventEntity event) {
    if (event.conversationId != _conversationId) return;

    switch (event.type) {
      case RealtimeMessageEventType.newMessage:
        final rawMessage = event.message;
        if (rawMessage == null) return;
        final message = _normalizeIncomingMessage(rawMessage);

        final exists = state.messages.any(
          (item) => item.id == message.id,
        );
        if (exists) {
          unawaited(markCurrentConversationAsRead());
          return;
        }

        final optimisticId = _findOptimisticMatchId(message);
        if (optimisticId != null) {
          emit(
            state.copyWith(
              messages: _replaceMessage(optimisticId, message),
              isSocketConnected: true,
              clearError: true,
            ),
          );
          unawaited(markCurrentConversationAsRead());
          return;
        }

        final merged = _sortMessages([
          ...state.messages,
          message,
        ]);

        emit(
          state.copyWith(
            messages: merged,
            isSocketConnected: true,
            clearError: true,
          ),
        );

        unawaited(markCurrentConversationAsRead());
        break;

      case RealtimeMessageEventType.messageDeleted:
        final messageId = event.messageId;
        if (messageId == null || messageId.isEmpty) return;

        emit(
          state.copyWith(
            messages: state.messages.map((message) {
              return message.id == messageId
                  ? _deletedMessage(message)
                  : message;
            }).toList(growable: false),
            isSocketConnected: true,
            clearError: true,
          ),
        );
        break;

      case RealtimeMessageEventType.userBlocked:
        _canMessage = false;
        emit(
          state.copyWith(
            isSocketConnected: true,
            errorMessage: event.blockReason ?? 'You cannot message this user.',
          ),
        );
        break;

      case RealtimeMessageEventType.userUnblocked:
        _canMessage = true;
        emit(
          state.copyWith(
            isSocketConnected: true,
            clearError: true,
          ),
        );
        break;

      default:
        emit(state.copyWith(isSocketConnected: true));
        break;
    }
  }

  List<MessageEntity> _sortMessages(List<MessageEntity> messages) {
    final list = [...messages];
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  MessageEntity _optimisticTextMessage(String text) {
    final now = DateTime.now();
    return MessageEntity(
      id: 'local-${now.microsecondsSinceEpoch}',
      conversationId: _conversationId ?? '',
      senderId: _currentUserId,
      receiverId: _receiverId,
      type: MessageType.text,
      text: text,
      isRead: false,
      createdAt: now,
      sharedTrack: null,
      sharedPlaylist: null,
    );
  }

  MessageEntity _normalizeSentMessage(
    MessageEntity message, {
    MessageEntity? fallback,
  }) {
    final fallbackDate = fallback?.createdAt ?? DateTime.now();
    final hasUsableDate = message.createdAt.year > 2000;
    final id = message.id.trim().isNotEmpty ? message.id : fallback?.id;
    final type = message.type == MessageType.unknown
        ? (fallback?.type ?? MessageType.text)
        : message.type;
    final text =
        (message.text ?? '').trim().isNotEmpty ? message.text : fallback?.text;

    return message.copyWith(
      id: id,
      conversationId: message.conversationId.trim().isNotEmpty
          ? message.conversationId
          : (_conversationId ?? fallback?.conversationId),
      senderId: message.senderId ?? _currentUserId ?? fallback?.senderId,
      receiverId: message.receiverId ?? _receiverId ?? fallback?.receiverId,
      type: type,
      text: text,
      createdAt: hasUsableDate ? message.createdAt.toLocal() : fallbackDate,
    );
  }

  MessageEntity _normalizeIncomingMessage(MessageEntity message) {
    return _normalizeSentMessage(message);
  }

  List<MessageEntity> _replaceMessage(
    String messageId,
    MessageEntity replacement,
  ) {
    final replacementAlreadyExists = state.messages.any(
      (message) => message.id == replacement.id && message.id != messageId,
    );
    var replaced = false;

    final messages = <MessageEntity>[];
    for (final message in state.messages) {
      if (message.id != messageId) {
        messages.add(message);
        continue;
      }

      replaced = true;
      if (!replacementAlreadyExists) {
        messages.add(replacement);
      }
    }

    if (!replaced && !replacementAlreadyExists) {
      messages.add(replacement);
    }

    return _sortMessages(messages);
  }

  String? _findOptimisticMatchId(MessageEntity message) {
    if (message.senderId != null &&
        _currentUserId != null &&
        message.senderId != _currentUserId) {
      return null;
    }

    for (final item in state.messages) {
      if (!item.id.startsWith('local-')) continue;
      if (item.type != message.type) continue;
      if ((item.text ?? '').trim() != (message.text ?? '').trim()) continue;

      final delta = item.createdAt.difference(message.createdAt).abs();
      if (delta.inSeconds <= 30) return item.id;
    }

    return null;
  }

  List<MessageEntity> _removeMessage(String messageId) {
    return state.messages
        .where((message) => message.id != messageId)
        .toList(growable: false);
  }

  MessageEntity _deletedMessage(MessageEntity message) {
    return message.copyWith(
      type: MessageType.text,
      clearText: true,
      clearSharedTrack: true,
      clearSharedPlaylist: true,
    );
  }

  void _appendSentMessage(MessageEntity message) {
    final normalized = _normalizeSentMessage(message);
    final exists = state.messages.any((item) => item.id == normalized.id);
    final messages = exists
        ? state.messages
        : _sortMessages([...state.messages, normalized]);

    emit(
      state.copyWith(
        isSending: false,
        messages: messages,
        clearError: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _socketSub?.cancel();

    // Do not disconnect the shared messaging socket here.
    // The Home unread badge may still be listening through UnreadCountCubit.
    return super.close();
  }
}