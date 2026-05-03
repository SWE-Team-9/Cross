import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/models/track.dart';
import '../../domain/entities/genre_entities.dart';
import '../../domain/entities/search_entities.dart';
import '../../domain/usecases/genre_usecase.dart';

part 'genre_state.dart';

@injectable
class GenreCubit extends Cubit<GenreState> {
  final GenreUseCase _genreUseCase;
  final FollowUserUseCase _followUseCase;

  GenreCubit(this._genreUseCase, this._followUseCase)
      : super(const GenreState());

  String _currentQuery = '';

  Future<void> load(String genreQuery) async {
    _currentQuery = genreQuery;
    emit(state.copyWith(isLoading: true, hasError: false));

    final result = await _genreUseCase(genreQuery);

    if (isClosed) return;

    result.fold(
      (_) => emit(
        state.copyWith(
          isLoading: false,
          hasError: true,
        ),
      ),
      (data) {
        final sortedTrending = List<Track>.from(data.trending)
          ..sort((a, b) => b.likesCount.compareTo(a.likesCount));

        emit(
          state.copyWith(
            isLoading: false,
            hasError: false,
            headerImageUrl: data.headerImageUrl,
            trending: sortedTrending,
            introducing: data.introducing,
            introducingExtras: data.introducingExtras,
            playlists: data.playlists,
            albums: data.albums,
            profiles: data.profiles,
            discoverMore: data.discoverMore,
            followingIds: data.followingIds,
          ),
        );
      },
    );
  }

  void retry() {
    if (_currentQuery.trim().isEmpty) return;
    load(_currentQuery);
  }

  Future<void> toggleFollow(String userId) async {
    if (userId.trim().isEmpty) return;

    final currentlyFollowing = state.followingIds.contains(userId);
    final updated = Set<String>.from(state.followingIds);

    if (currentlyFollowing) {
      updated.remove(userId);
    } else {
      updated.add(userId);
    }

    emit(state.copyWith(followingIds: updated));

    final result = await _followUseCase(
      userId: userId,
      follow: !currentlyFollowing,
    );

    if (isClosed) return;

    result.fold(
      (_) {
        final reverted = Set<String>.from(state.followingIds);

        if (currentlyFollowing) {
          reverted.add(userId);
        } else {
          reverted.remove(userId);
        }

        emit(state.copyWith(followingIds: reverted));
      },
      (_) {},
    );
  }
}
