import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/share_playlist_message_usecase.dart';
import '../../domain/usecases/share_track_message_usecase.dart';
import 'share_track_to_conversation_state.dart';

class ShareTrackToConversationCubit
    extends Cubit<ShareTrackToConversationState> {
  final GetConversationsUseCase getConversationsUseCase;
  final ShareTrackMessageUseCase shareTrackMessageUseCase;
  final SharePlaylistMessageUseCase sharePlaylistMessageUseCase;

  ShareTrackToConversationCubit({
    required this.getConversationsUseCase,
    required this.shareTrackMessageUseCase,
    required this.sharePlaylistMessageUseCase,
  }) : super(ShareTrackToConversationState.initial());

  Future<void> loadInitial() async {
    emit(
      state.copyWith(
        isLoadingConversations: true,
        conversations: const [],
        page: 1,
        hasMore: true,
        clearError: true,
        clearSuccess: true,
        clearSelectedConversation: true,
      ),
    );

    try {
      final pageData = await getConversationsUseCase(
        page: 1,
        limit: 20,
      );

      emit(
        state.copyWith(
          isLoadingConversations: false,
          conversations: pageData.conversations,
          page: pageData.page,
          hasMore: pageData.hasMore,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingConversations: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingConversations || state.isSharing || !state.hasMore) {
      return;
    }

    try {
      final nextPage = state.page + 1;
      final pageData = await getConversationsUseCase(
        page: nextPage,
        limit: 20,
      );

      emit(
        state.copyWith(
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
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> shareTrack({
    required ConversationEntity conversation,
    required String trackId,
    String? text,
  }) async {
    if (state.isSharing) return;

    emit(
      state.copyWith(
        isSharing: true,
        selectedConversationId: conversation.conversationId,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await shareTrackMessageUseCase(
        receiverId: conversation.participant.id,
        trackId: trackId,
        text: text,
      );

      emit(
        state.copyWith(
          isSharing: false,
          successMessage:
              'Track sent to ${conversation.participant.displayName}',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSharing: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> sharePlaylist({
    required ConversationEntity conversation,
    required String playlistId,
    String? text,
  }) async {
    if (state.isSharing) return;

    emit(
      state.copyWith(
        isSharing: true,
        selectedConversationId: conversation.conversationId,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      await sharePlaylistMessageUseCase(
        receiverId: conversation.participant.id,
        playlistId: playlistId,
        text: text,
      );

      emit(
        state.copyWith(
          isSharing: false,
          successMessage:
              'Playlist sent to ${conversation.participant.displayName}',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSharing: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
