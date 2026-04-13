import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_track_likers_usecase.dart';
import '../../domain/usecases/get_track_reposters_usecase.dart';
import 'engagement_list_state.dart';

class EngagementListCubit extends Cubit<EngagementListState> {
  final GetTrackLikersUseCase getTrackLikersUseCase;
  final GetTrackRepostersUseCase getTrackRepostersUseCase;

  EngagementListCubit({
    required this.getTrackLikersUseCase,
    required this.getTrackRepostersUseCase,
  }) : super(EngagementListState.initial());

  Future<void> load({
    required String trackId,
    required EngagementListType type,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
        trackId: trackId,
        type: type,
        page: 1,
        items: [],
        hasNextPage: true,
        clearError: true,
      ),
    );

    try {
      final result = await _fetch(trackId: trackId, type: type, page: 1);

      emit(
        state.copyWith(
          isLoading: false,
          items: result.items,
          page: result.page,
          hasNextPage: result.hasNextPage,
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

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasNextPage) return;

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final nextPage = state.page + 1;
      final result = await _fetch(
        trackId: state.trackId,
        type: state.type,
        page: nextPage,
      );

      emit(
        state.copyWith(
          isLoadingMore: false,
          items: [...state.items, ...result.items],
          page: result.page,
          hasNextPage: result.hasNextPage,
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

  Future<dynamic> _fetch({
    required String trackId,
    required EngagementListType type,
    required int page,
  }) {
    switch (type) {
      case EngagementListType.likers:
        return getTrackLikersUseCase(trackId, page: page);
      case EngagementListType.reposters:
        return getTrackRepostersUseCase(trackId, page: page);
    }
  }
}