import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_conversations_usecase.dart';
import 'inbox_state.dart';

class InboxCubit extends Cubit<InboxState> {
  final GetConversationsUseCase getConversationsUseCase;

  InboxCubit({
    required this.getConversationsUseCase,
  }) : super(InboxState.initial());

  Future<void> loadInitial() async {
    emit(
      state.copyWith(
        isLoading: true,
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
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true, clearError: true));

    try {
      final pageData = await getConversationsUseCase(
        page: 1,
        limit: 20,
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
}