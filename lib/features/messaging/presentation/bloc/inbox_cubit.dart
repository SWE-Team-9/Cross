import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/realtime_message_event_entity.dart';
import '../../domain/usecases/archive_conversation_usecase.dart';
import '../../domain/usecases/connect_messaging_socket_usecase.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
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
  final DeleteConversationUseCase deleteConversationUseCase;
  final ConnectMessagingSocketUseCase connectMessagingSocketUseCase;

  StreamSubscription<RealtimeMessageEventEntity>? _socketSub;

  InboxCubit({
    required this.getConversationsUseCase,
    required this.markConversationReadUseCase,
    required this.markConversationUnreadUseCase,
    required this.archiveConversationUseCase,
    required this.unarchiveConversationUseCase,
    required this.deleteConversationUseCase,
    required this.connectMessagingSocketUseCase,
  }) : super(InboxState.initial());

  // --- Initial Load & View Toggles ---

  Future<void> loadInitial({bool? archived}) async {
    final archivedMode = archived ?? state.isArchivedMode;

    emit(state.copyWith(
      isLoading: true,
      isArchivedMode: archivedMode,
      clearError: true,
      conversations: const [],
      page: 1,
      hasMore: true,
    ));

    try {
      final pageData = await getConversationsUseCase(
        page: 1,
        limit: 20,
        archived: archivedMode,
      );

      emit(state.copyWith(
        isLoading: false,
        conversations: _sortConversations(pageData.conversations),
        page: pageData.page,
        hasMore: pageData.hasMore,
        clearError: true,
      ));

      await _connectSocket();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> toggleArchivedMode() async {
    await loadInitial(archived: !state.isArchivedMode);
  }

  // --- Core Fetching & Refresh Logic ---

  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    try {
      final pageData = await getConversationsUseCase(
        page: 1,
        limit: 20,
        archived: state.isArchivedMode,
      );

      emit(state.copyWith(
        isRefreshing: false,
        conversations: _sortConversations(pageData.conversations),
        page: pageData.page,
        hasMore: pageData.hasMore,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(isRefreshing: false, errorMessage: e.toString()));
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

      emit(state.copyWith(
        isLoadingMore: false,
        conversations: _sortConversations([
          ...state.conversations,
          ...pageData.conversations,
        ]),
        page: pageData.page,
        hasMore: pageData.hasMore,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: e.toString()));
    }
  }

  // --- Manual Actions ---

  Future<void> markConversationAsRead(String conversationId) async {
    // Optimistic local update
    final updated = state.conversations.map((c) {
      return c.conversationId == conversationId
          ? c.copyWith(unreadCount: 0)
          : c;
    }).toList();
    emit(state.copyWith(conversations: updated, clearError: true));

    try {
      await markConversationReadUseCase(conversationId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> markConversationAsUnread(String conversationId) async {
    final updated = state.conversations.map((c) {
      return c.conversationId == conversationId
          ? c.copyWith(unreadCount: 1)
          : c;
    }).toList();
    emit(state.copyWith(conversations: updated, clearError: true));

    try {
      await markConversationUnreadUseCase(conversationId);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> archiveConversation(String conversationId) async {
    final originalList = List<ConversationEntity>.from(state.conversations);
    emit(state.copyWith(
      conversations: state.conversations
          .where((c) => c.conversationId != conversationId)
          .toList(),
    ));

    try {
      await archiveConversationUseCase(conversationId);
    } catch (e) {
      emit(state.copyWith(conversations: originalList, errorMessage: e.toString()));
    }
  }

  Future<void> unarchiveConversation(String conversationId) async {
    final originalList = List<ConversationEntity>.from(state.conversations);
    emit(state.copyWith(
      conversations: state.conversations
          .where((c) => c.conversationId != conversationId)
          .toList(),
    ));

    try {
      await unarchiveConversationUseCase(conversationId);
    } catch (e) {
      emit(state.copyWith(conversations: originalList, errorMessage: e.toString()));
    }
  }

  Future<void> deleteConversation(
    String conversationId, {
    String? messageId,
  }) async {
    final originalList = List<ConversationEntity>.from(state.conversations);
    emit(state.copyWith(
      conversations: state.conversations
          .where((c) => c.conversationId != conversationId)
          .toList(),
      clearError: true,
    ));

    try {
      final targetId = (messageId ?? '').trim().isNotEmpty
          ? messageId!.trim()
          : conversationId;
      await deleteConversationUseCase(targetId);
    } catch (e) {
      emit(state.copyWith(conversations: originalList, errorMessage: e.toString()));
    }
  }

  // --- Socket Connections ---

  Future<void> _connectSocket() async {
    try {
      await connectMessagingSocketUseCase();
      await _socketSub?.cancel();
      _socketSub = connectMessagingSocketUseCase.eventsStream.listen(
        _handleSocketEvent,
        onError: (_) {},
      );
    } catch (_) {}
  }

  // Whenever ANY realtime socket event comes in, we call refresh() to fetch the true state from the server.
  void _handleSocketEvent(RealtimeMessageEventEntity event) {
    switch (event.type) {
      case RealtimeMessageEventType.newMessage:
      case RealtimeMessageEventType.conversationRead:
      case RealtimeMessageEventType.conversationUpdated:
      case RealtimeMessageEventType.messageDeleted:
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
      final aDate = a.lastMessage?.createdAt ?? a.updatedAt ?? DateTime(0);
      final bDate = b.lastMessage?.createdAt ?? b.updatedAt ?? DateTime(0);
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