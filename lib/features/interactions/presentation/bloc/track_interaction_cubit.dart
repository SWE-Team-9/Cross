import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_track_interaction_status_usecase.dart';
import '../../domain/usecases/like_track_usecase.dart';
import '../../domain/usecases/repost_track_usecase.dart';
import '../../domain/usecases/unlike_track_usecase.dart';
import '../../domain/usecases/unrepost_track_usecase.dart';
import 'track_interaction_state.dart';

class TrackInteractionCubit extends Cubit<TrackInteractionState> {
  final GetTrackInteractionStatusUseCase getTrackInteractionStatusUseCase;
  final LikeTrackUseCase likeTrackUseCase;
  final UnlikeTrackUseCase unlikeTrackUseCase;
  final RepostTrackUseCase repostTrackUseCase;
  final UnrepostTrackUseCase unrepostTrackUseCase;

  TrackInteractionCubit({
    required this.getTrackInteractionStatusUseCase,
    required this.likeTrackUseCase,
    required this.unlikeTrackUseCase,
    required this.repostTrackUseCase,
    required this.unrepostTrackUseCase,
  }) : super(TrackInteractionState.initial());

  Future<void> load(String trackId) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final status = await getTrackInteractionStatusUseCase(trackId);

      emit(
        state.copyWith(
          isLoading: false,
          isLiked: status.isLiked,
          isReposted: status.isReposted,
          likesCount: status.likesCount,
          repostsCount: status.repostsCount,
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

  Future<void> toggleLike(String trackId) async {
    if (state.isSubmittingLike) return;

    final previousLiked = state.isLiked;
    final previousCount = state.likesCount;

    final nextLiked = !previousLiked;
    final nextCount = nextLiked
        ? previousCount + 1
        : (previousCount > 0 ? previousCount - 1 : 0);

    emit(
      state.copyWith(
        isSubmittingLike: true,
        isLiked: nextLiked,
        likesCount: nextCount,
        clearError: true,
      ),
    );

    try {
      if (previousLiked) {
        await unlikeTrackUseCase(trackId);
      } else {
        await likeTrackUseCase(trackId);
      }

      emit(state.copyWith(isSubmittingLike: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSubmittingLike: false,
          isLiked: previousLiked,
          likesCount: previousCount,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> toggleRepost(String trackId) async {
    if (state.isSubmittingRepost) return;

    final previousReposted = state.isReposted;
    final previousCount = state.repostsCount;

    final nextReposted = !previousReposted;
    final nextCount = nextReposted
        ? previousCount + 1
        : (previousCount > 0 ? previousCount - 1 : 0);

    emit(
      state.copyWith(
        isSubmittingRepost: true,
        isReposted: nextReposted,
        repostsCount: nextCount,
        clearError: true,
      ),
    );

    try {
      if (previousReposted) {
        await unrepostTrackUseCase(trackId);
      } else {
        await repostTrackUseCase(trackId);
      }

      emit(state.copyWith(isSubmittingRepost: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSubmittingRepost: false,
          isReposted: previousReposted,
          repostsCount: previousCount,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
