import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/features/library/presentation/bloc/library_state.dart';
import 'package:soundcloud_clone/features/playlists/data/local/recent_playlists_store.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_liked_playlists_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_recent_playlists_usecase.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final GetRecentPlaylistsUseCase getRecentPlaylistsUseCase;
  final GetLikedPlaylistsUseCase getLikedPlaylistsUseCase;
  final RecentPlaylistsStore recentPlaylistsStore;

  LibraryCubit({
    required this.getRecentPlaylistsUseCase,
    required this.getLikedPlaylistsUseCase,
    this.recentPlaylistsStore = const RecentPlaylistsStore(),
  }) : super(LibraryState.initial());

  Future<void> loadLibraryPlaylists() async {
    if (isClosed) return;

    await Future.wait([
      loadRecentPlaylists(),
      loadLikedPlaylists(),
    ]);
  }

  Future<void> loadRecentPlaylists({int limit = 10}) async {
    if (isClosed) return;

    var localPlaylists = const <PlaylistEntity>[];

    _emitIfOpen(
      state.copyWith(
        isLoadingRecentPlaylists: true,
        clearError: true,
      ),
    );

    try {
      localPlaylists = await recentPlaylistsStore.load(limit: limit);
      if (isClosed) return;

      if (localPlaylists.isNotEmpty) {
        _emitIfOpen(
          state.copyWith(
            recentPlaylists: localPlaylists,
            isLoadingRecentPlaylists: true,
          ),
        );
      }

      final remotePlaylists = await getRecentPlaylistsUseCase(limit: limit);
      _emitIfOpen(
        state.copyWith(
          recentPlaylists: _mergePlaylists(
            remotePlaylists,
            localPlaylists,
            limit: limit,
          ),
          isLoadingRecentPlaylists: false,
          clearError: true,
        ),
      );
    } catch (_) {
      _emitIfOpen(
        state.copyWith(
          recentPlaylists: localPlaylists,
          isLoadingRecentPlaylists: false,
          errorMessage: 'Could not load recent playlists',
        ),
      );
    }
  }

  Future<void> loadLikedPlaylists({
    int page = 1,
    int limit = 20,
  }) async {
    if (isClosed) return;

    _emitIfOpen(
      state.copyWith(
        isLoadingLikedPlaylists: true,
        clearError: true,
      ),
    );

    try {
      final playlists = await getLikedPlaylistsUseCase(
        page: page,
        limit: limit,
      );

      _emitIfOpen(
        state.copyWith(
          likedPlaylists: playlists,
          isLoadingLikedPlaylists: false,
          clearError: true,
        ),
      );
    } catch (_) {
      _emitIfOpen(
        state.copyWith(
          likedPlaylists: const <PlaylistEntity>[],
          isLoadingLikedPlaylists: false,
          errorMessage: 'Could not load liked playlists',
        ),
      );
    }
  }

  List<PlaylistEntity> _mergePlaylists(
    List<PlaylistEntity> primary,
    List<PlaylistEntity> fallback, {
    required int limit,
  }) {
    final merged = <PlaylistEntity>[];
    final seenIds = <String>{};

    for (final playlist in [...primary, ...fallback]) {
      if (playlist.playlistId.isEmpty || !seenIds.add(playlist.playlistId)) {
        continue;
      }

      merged.add(playlist);
      if (merged.length >= limit) break;
    }

    return merged;
  }

  void _emitIfOpen(LibraryState nextState) {
    if (!isClosed) emit(nextState);
  }
}
