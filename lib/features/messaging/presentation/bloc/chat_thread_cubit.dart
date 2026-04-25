import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/message_entity.dart';
import '../../domain/entities/realtime_message_event_entity.dart';
import '../../domain/usecases/connect_messaging_socket_usecase.dart';
import '../../domain/usecases/delete_message_usecase.dart';
import '../../domain/usecases/get_conversation_messages_usecase.dart';
import '../../domain/usecases/mark_conversation_read_usecase.dart';
import '../../domain/usecases/send_text_message_usecase.dart';
import 'chat_thread_state.dart';

class ChatThreadCubit extends Cubit<ChatThreadState> {
  final GetConversationMessagesUseCase getConversationMessagesUseCase;
  final SendTextMessageUseCase sendTextMessageUseCase;
  final MarkConversationReadUseCase markConversationReadUseCase;
  final DeleteMessageUseCase deleteMessageUseCase;
  final ConnectMessagingSocketUseCase connectMessagingSocketUseCase;

  StreamSubscription<RealtimeMessageEventEntity>? _socketSub;

  String? _conversationId;
  String? _receiverId;
  bool _canMessage = true;

  ChatThreadCubit({
    required this.getConversationMessagesUseCase,
    required this.sendTextMessageUseCase,
    required this.markConversationReadUseCase,
    required this.deleteMessageUseCase,
    required this.connectMessagingSocketUseCase,
  }) : super(ChatThreadState.initial());

  Future<void> load({
    required String conversationId,
    required String receiverId,
    bool canMessage = true,
  }) async {
    _conversationId = conversationId;
    _receiverId = receiverId;
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

      await markConversationReadUseCase(conversationId);
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
      emit(
        state.copyWith(
          errorMessage: 'You cannot message this user.',
        ),
      );
      return;
    }

    final receiverId = _receiverId;
    if (receiverId == null) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    emit(state.copyWith(isSending: true, clearError: true));

    try {
      final message = await sendTextMessageUseCase(
        receiverId: receiverId,
        text: trimmed,
      );

      final merged = _sortMessages([
        ...state.messages,
        message,
      ]);

      emit(
        state.copyWith(
          isSending: false,
          messages: merged,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSending: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await deleteMessageUseCase(messageId);

      emit(
        state.copyWith(
          messages: state.messages
              .where((message) => message.id != messageId)
              .toList(growable: false),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
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
      final message = event.message;
      if (message == null) return;

      final exists = state.messages.any(
        (item) => item.id == message.id,
      );
      if (exists) return;

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
      break;

    case RealtimeMessageEventType.messageDeleted:
      final messageId = event.messageId;
      if (messageId == null || messageId.isEmpty) return;

      emit(
        state.copyWith(
          messages: state.messages
              .where((message) => message.id != messageId)
              .toList(growable: false),
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

    case RealtimeMessageEventType.conversationRead:
    case RealtimeMessageEventType.conversationUpdated:
    case RealtimeMessageEventType.unreadCountUpdated:
    case RealtimeMessageEventType.unknown:
      emit(
        state.copyWith(
          isSocketConnected: true,
        ),
      );
      break;
  }
}

  List<MessageEntity> _sortMessages(List<MessageEntity> messages) {
    final list = [...messages];
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<void> close() async {
    await _socketSub?.cancel();

    // Do not disconnect the shared messaging socket here.
    // The Home unread badge may still be listening through UnreadCountCubit.
    return super.close();
  }
}