import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/realtime_message_event_entity.dart';
import '../../domain/usecases/archive_conversation_usecase.dart';
import '../../domain/usecases/connect_messaging_socket_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/mark_conversation_read_usecase.dart';
import '../../domain/usecases/mark_conversation_unread_usecase.dart';
import '../../domain/usecases/unarchive_conversation_usecase.dart';
import 'inbox_state.dart';

class InboxCubit extends Cubit<InboxState> {
  final GetConversationsUseCase getConversationsUseCase;
  final MarkConversationReadUseCase markConversationReadUseCase;
  final MarkConversationUnreadUseCase markConversationUnreadUseCase;
  final ArchiveConversationUseCase archiveConversationUseCase;
  final UnarchiveConversationUseCase unarchiveConversationUseCase;
  final ConnectMessagingSocketUseCase connectMessagingSocketUseCase;

  StreamSubscription<RealtimeMessageEventEntity>? _socketSub;

  InboxCubit({
    required this.getConversationsUseCase,
    required this.markConversationReadUseCase,
    required this.markConversationUnreadUseCase,
    required this.archiveConversationUseCase,
    required this.unarchiveConversationUseCase,
    required this.connectMessagingSocketUseCase,
  }) : super(InboxState.initial());

  Future<void> loadInitial({bool? archived}) async {
    final archivedMode = archived ?? state.isArchivedMode;

    emit(
      state.copyWith(
        isLoading: true,
        isArchivedMode: archivedMode,
        clearError: true,
        conversations: const [],
        page: 1,
        hasMore: true,
      ),
    );

    try {
      final pageData = await getConversationsUseCase(
        page: 1,
        limit: 20,
        archived: archivedMode,
      );

      emit(
        state.copyWith(
          isLoading: false,
          conversations: pageData.conversations,
          page: pageData.page,
          hasMore: pageData.hasMore,
          clearError: true,
        ),
      );

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

  Future<void> toggleArchivedMode() async {
    await loadInitial(archived: !state.isArchivedMode);
  }

  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true, clearError: true));

    try {
      final pageData = await getConversationsUseCase(
        page: 1,
        limit: 20,
        archived: state.isArchivedMode,
      );

      emit(
        state.copyWith(
          isRefreshing: false,
          conversations: pageData.conversations,
          page: pageData.page,
          hasMore: pageData.hasMore,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final nextPage = state.page + 1;
      final pageData = await getConversationsUseCase(
        page: nextPage,
        limit: 20,
        archived: state.isArchivedMode,
      );

      emit(
        state.copyWith(
          isLoadingMore: false,
          conversations: [
            ...state.conversations,
            ...pageData.conversations,
          ],
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

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await markConversationReadUseCase(conversationId);

      emit(
        state.copyWith(
          conversations: state.conversations
              .map(
                (conversation) => conversation.conversationId == conversationId
                    ? conversation.copyWith(unreadCount: 0)
                    : conversation,
              )
              .toList(growable: false),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> markConversationAsUnread(String conversationId) async {
    try {
      await markConversationUnreadUseCase(conversationId);

      emit(
        state.copyWith(
          conversations: state.conversations
              .map(
                (conversation) => conversation.conversationId == conversationId
                    ? conversation.copyWith(unreadCount: 1)
                    : conversation,
              )
              .toList(growable: false),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> archiveConversation(String conversationId) async {
    try {
      await archiveConversationUseCase(conversationId);

      emit(
        state.copyWith(
          conversations: state.conversations
              .where(
                (conversation) => conversation.conversationId != conversationId,
              )
              .toList(growable: false),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> unarchiveConversation(String conversationId) async {
    try {
      await unarchiveConversationUseCase(conversationId);

      emit(
        state.copyWith(
          conversations: state.conversations
              .where(
                (conversation) => conversation.conversationId != conversationId,
              )
              .toList(growable: false),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void upsertConversation(ConversationEntity conversation) {
    final index = state.conversations.indexWhere(
      (item) => item.conversationId == conversation.conversationId,
    );

    final updated = [...state.conversations];

    if (index >= 0) {
      updated[index] = conversation;
    } else if (conversation.isArchived == state.isArchivedMode) {
      updated.insert(0, conversation);
    }

    emit(
      state.copyWith(
        conversations: _sortConversations(updated),
        clearError: true,
      ),
    );
  }

  Future<void> _connectSocket() async {
    try {
      await connectMessagingSocketUseCase();
      await _socketSub?.cancel();
      _socketSub = connectMessagingSocketUseCase.eventsStream.listen(
        _handleSocketEvent,
        onError: (_) {},
      );
    } catch (_) {
      // Inbox still works with manual refresh if realtime is unavailable.
    }
  }

  void _handleSocketEvent(RealtimeMessageEventEntity event) {
    switch (event.type) {
      case RealtimeMessageEventType.conversationUpdated:
        final conversation = event.conversation;
        if (conversation != null) {
          upsertConversation(conversation);
        } else {
          unawaited(refresh());
        }
        break;
      case RealtimeMessageEventType.newMessage:
      case RealtimeMessageEventType.messageDeleted:
      case RealtimeMessageEventType.conversationRead:
        unawaited(refresh());
        break;
      default:
        break;
    }
  }

  List<ConversationEntity> _sortConversations(
    List<ConversationEntity> conversations,
  ) {
    final list = [...conversations];
    list.sort((a, b) {
      final aDate = a.updatedAt ?? a.lastMessage?.createdAt;
      final bDate = b.updatedAt ?? b.lastMessage?.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return list;
  }

  @override
  Future<void> close() async {
    await _socketSub?.cancel();
    return super.close();
  }
}
