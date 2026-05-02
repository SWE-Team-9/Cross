// ─────────────────────────────────────────────────────────────────────────────
//  track_interaction_cubit.dart
//
//  load() يجيب isLiked/isReposted من status endpoint فقط.
//  الـ counts بتيجي من الـ feed response مباشرة (likesCount, repostsCount)
//  ومش محتاجين GET /api/v1/tracks/{id} في كل card.
// ─────────────────────────────────────────────────────────────────────────────

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

  // ── load ──────────────────────────────────────────────────────────────────
  // counts بتيجي من الـ caller (feed response أو track detail)
  // isLiked/isReposted بيجوا من status endpoint
  Future<void> load({
    required String trackId,
    int likesCount = 0,
    int repostsCount = 0,
  }) async {
    emit(state.copyWith(
      isLoading: true,
      likesCount: likesCount,
      repostsCount: repostsCount,
      clearError: true,
    ));

    try {
      final status = await getTrackInteractionStatusUseCase(trackId);
      if (isClosed) return;

      emit(state.copyWith(
        isLoading: false,
        isLiked: status.isLiked,
        isReposted: status.isReposted,
        clearError: true,
      ));
    } catch (e) {
      if (isClosed) return;
      // لو الـ status endpoint فشل، نكمل بالـ counts اللي عندنا
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── loadWithKnownState ────────────────────────────────────────────────────
  // لما الـ feed response بيجيب liked/reposted بالفعل — مش محتاجين API call
  void loadWithKnownState({
    required String trackId,
    required int likesCount,
    required int repostsCount,
    required bool isLiked,
    required bool isReposted,
  }) {
    emit(state.copyWith(
      isLoading: false,
      likesCount: likesCount,
      repostsCount: repostsCount,
      isLiked: isLiked,
      isReposted: isReposted,
      clearError: true,
    ));
  }

  // ── toggleLike ────────────────────────────────────────────────────────────

  Future<void> toggleLike(String trackId) async {
    if (state.isSubmittingLike) return;

    final wasLiked = state.isLiked;
    final prevCount = state.likesCount;
    final nextCount =
        wasLiked ? (prevCount > 0 ? prevCount - 1 : 0) : prevCount + 1;

    emit(state.copyWith(
      isSubmittingLike: true,
      isLiked: !wasLiked,
      likesCount: nextCount,
      clearError: true,
    ));

    try {
      if (wasLiked) {
        await unlikeTrackUseCase(trackId);
      } else {
        await likeTrackUseCase(trackId);
      }
      emit(state.copyWith(isSubmittingLike: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isSubmittingLike: false,
        isLiked: wasLiked,
        likesCount: prevCount,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── toggleRepost ──────────────────────────────────────────────────────────

  Future<void> toggleRepost(String trackId) async {
    if (state.isSubmittingRepost) return;

    final wasReposted = state.isReposted;
    final prevCount = state.repostsCount;
    final nextCount = wasReposted
        ? (prevCount > 0 ? prevCount - 1 : 0)
        : prevCount + 1;

    emit(state.copyWith(
      isSubmittingRepost: true,
      isReposted: !wasReposted,
      repostsCount: nextCount,
      clearError: true,
    ));

    try {
      if (wasReposted) {
        await unrepostTrackUseCase(trackId);
      } else {
        await repostTrackUseCase(trackId);
      }
      emit(state.copyWith(isSubmittingRepost: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isSubmittingRepost: false,
        isReposted: wasReposted,
        repostsCount: prevCount,
        errorMessage: e.toString(),
      ));
    }
  }
}