// // lib/features/search/presentation/bloc/genre_cubit.dart
// //
// // Manages all data for the genre / vibe page:
// //   trending, introducing, playlists, albums, profiles, discoverMore
// //   + follow toggling (wired to real follow system)
// // ─────────────────────────────────────────────────────────────────────────────

// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:injectable/injectable.dart';

// import '../../../../core/models/track.dart';
// import '../../domain/entities/search_entities.dart';
// import '../../domain/usecases/genre_usecase.dart';

// part 'genre_state.dart';

// @injectable
// class GenreCubit extends Cubit<GenreState> {
//   final GenreUseCase _genreUseCase;
//   final FollowUserUseCase _followUseCase;

//   GenreCubit(this._genreUseCase, this._followUseCase)
//       : super(const GenreState());

//   String _currentQuery = '';

//   // ── Load ──────────────────────────────────────────────────────────────────

//   Future<void> load(String genreQuery) async {
//     _currentQuery = genreQuery;
//     emit(state.copyWith(isLoading: true, hasError: false));

//     final result = await _genreUseCase(genreQuery);
//     if (isClosed) return;

//     result.fold(
//       (failure) => emit(state.copyWith(isLoading: false, hasError: true)),
//       (data) {
//         // Sort trending by playbackCount descending
//         final sorted = List<Track>.from(data.trending)
//           ..sort((a, b) =>
//               b.playbackCount.compareTo(a.playbackCount));

//         emit(state.copyWith(
//           isLoading:         false,
//           hasError:          false,
//           headerImageUrl:    data.headerImageUrl,
//           trending:          sorted,
//           introducing:       data.introducing,
//           introducingExtras: data.introducingExtras,
//           playlists:         data.playlists,
//           albums:            data.albums,
//           profiles:          data.profiles,
//           discoverMore:      data.discoverMore,
//           followingIds:      data.followingIds,
//         ));
//       },
//     );
//   }

//   void retry() => load(_currentQuery);

//   // ── Follow ────────────────────────────────────────────────────────────────

//   Future<void> toggleFollow(String userId) async {
//     final currentlyFollowing = state.followingIds.contains(userId);
//     // Optimistic update
//     final updated = Set<String>.from(state.followingIds);
//     if (currentlyFollowing) {
//       updated.remove(userId);
//     } else {
//       updated.add(userId);
//     }
//     emit(state.copyWith(followingIds: updated));

//     // Call real API
//     final result = await _followUseCase(
//       userId: userId,
//       follow: !currentlyFollowing,
//     );
//     if (isClosed) return;

//     result.fold(
//       // Revert on failure
//       (_) {
//         final reverted = Set<String>.from(state.followingIds);
//         if (currentlyFollowing) {
//           reverted.add(userId);
//         } else {
//           reverted.remove(userId);
//         }
//         emit(state.copyWith(followingIds: reverted));
//       },
//       (_) {}, // success — keep optimistic state
//     );
//   }
// }
