import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/library/presentation/bloc/library_cubit.dart';
import 'package:soundcloud_clone/features/library/presentation/bloc/library_state.dart';
import 'package:soundcloud_clone/features/playlists/data/local/recent_playlists_store.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_liked_playlists_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_recent_playlists_usecase.dart';

class MockGetRecentPlaylistsUseCase extends Mock
    implements GetRecentPlaylistsUseCase {}

class MockGetLikedPlaylistsUseCase extends Mock
    implements GetLikedPlaylistsUseCase {}

class MockRecentPlaylistsStore extends Mock implements RecentPlaylistsStore {}

void main() {
  late MockGetRecentPlaylistsUseCase getRecent;
  late MockGetLikedPlaylistsUseCase getLiked;
  late MockRecentPlaylistsStore recentStore;

  setUp(() {
    getRecent = MockGetRecentPlaylistsUseCase();
    getLiked = MockGetLikedPlaylistsUseCase();
    recentStore = MockRecentPlaylistsStore();
  });

  LibraryCubit buildCubit() {
    return LibraryCubit(
      getRecentPlaylistsUseCase: getRecent,
      getLikedPlaylistsUseCase: getLiked,
      recentPlaylistsStore: recentStore,
    );
  }

  group('LibraryCubit', () {
    test('initial state is empty', () {
      final cubit = buildCubit();

      expect(cubit.state.isLoadingRecentPlaylists, isFalse);
      expect(cubit.state.isLoadingLikedPlaylists, isFalse);
      expect(cubit.state.recentPlaylists, isEmpty);
      expect(cubit.state.likedPlaylists, isEmpty);
      expect(cubit.state.errorMessage, isNull);
    });

    blocTest<LibraryCubit, LibraryState>(
      'loadRecentPlaylists emits local cache then merged remote playlists',
      build: () {
        when(() => recentStore.load(limit: 10)).thenAnswer(
          (_) async => [_playlist(id: 'pl_local', title: 'Local Playlist')],
        );
        when(() => getRecent(limit: 10)).thenAnswer(
          (_) async => [
            _playlist(id: 'pl_remote', title: 'Remote Playlist'),
            _playlist(id: 'pl_local', title: 'Local Playlist'),
          ],
        );

        return buildCubit();
      },
      act: (cubit) => cubit.loadRecentPlaylists(),
      expect: () => [
        isA<LibraryState>()
            .having(
              (state) => state.isLoadingRecentPlaylists,
              'loading recent',
              isTrue,
            )
            .having(
              (state) => state.recentPlaylists,
              'recent playlists',
              isEmpty,
            ),
        isA<LibraryState>()
            .having(
              (state) => state.isLoadingRecentPlaylists,
              'loading recent',
              isTrue,
            )
            .having(
              (state) => state.recentPlaylists.length,
              'local count',
              1,
            )
            .having(
              (state) => state.recentPlaylists.single.playlistId,
              'local id',
              'pl_local',
            ),
        isA<LibraryState>()
            .having(
              (state) => state.isLoadingRecentPlaylists,
              'loading recent',
              isFalse,
            )
            .having(
              (state) => state.recentPlaylists.length,
              'merged count',
              2,
            )
            .having(
              (state) => state.recentPlaylists.first.playlistId,
              'first id',
              'pl_remote',
            )
            .having(
              (state) => state.recentPlaylists.last.playlistId,
              'last id',
              'pl_local',
            ),
      ],
      verify: (_) {
        verify(() => recentStore.load(limit: 10)).called(1);
        verify(() => getRecent(limit: 10)).called(1);
      },
    );

    blocTest<LibraryCubit, LibraryState>(
      'loadRecentPlaylists falls back to local cache when remote fails',
      build: () {
        when(() => recentStore.load(limit: 10)).thenAnswer(
          (_) async => [_playlist(id: 'pl_local', title: 'Local Playlist')],
        );
        when(() => getRecent(limit: 10)).thenThrow(Exception('network failed'));

        return buildCubit();
      },
      act: (cubit) => cubit.loadRecentPlaylists(),
      expect: () => [
        isA<LibraryState>().having(
          (state) => state.isLoadingRecentPlaylists,
          'loading recent',
          isTrue,
        ),
        isA<LibraryState>()
            .having(
              (state) => state.isLoadingRecentPlaylists,
              'loading recent',
              isTrue,
            )
            .having(
              (state) => state.recentPlaylists.single.playlistId,
              'local id',
              'pl_local',
            ),
        isA<LibraryState>()
            .having(
              (state) => state.isLoadingRecentPlaylists,
              'loading recent',
              isFalse,
            )
            .having(
              (state) => state.recentPlaylists.single.playlistId,
              'fallback id',
              'pl_local',
            )
            .having(
              (state) => state.errorMessage,
              'error',
              'Could not load recent playlists',
            ),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'loadRecentPlaylists handles empty local cache',
      build: () {
        when(() => recentStore.load(limit: 10)).thenAnswer(
          (_) async => const <PlaylistEntity>[],
        );
        when(() => getRecent(limit: 10)).thenAnswer(
          (_) async => [_playlist(id: 'pl_remote', title: 'Remote Playlist')],
        );

        return buildCubit();
      },
      act: (cubit) => cubit.loadRecentPlaylists(),
      expect: () => [
        isA<LibraryState>().having(
          (state) => state.isLoadingRecentPlaylists,
          'loading recent',
          isTrue,
        ),
        isA<LibraryState>()
            .having(
              (state) => state.isLoadingRecentPlaylists,
              'loading recent',
              isFalse,
            )
            .having(
              (state) => state.recentPlaylists.single.playlistId,
              'remote id',
              'pl_remote',
            ),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'loadLikedPlaylists emits liked playlists',
      build: () {
        when(() => getLiked(page: 1, limit: 20)).thenAnswer(
          (_) async => [_playlist(id: 'pl_liked', title: 'Liked Playlist')],
        );

        return buildCubit();
      },
      act: (cubit) => cubit.loadLikedPlaylists(),
      expect: () => [
        isA<LibraryState>().having(
          (state) => state.isLoadingLikedPlaylists,
          'loading liked',
          isTrue,
        ),
        isA<LibraryState>()
            .having(
              (state) => state.isLoadingLikedPlaylists,
              'loading liked',
              isFalse,
            )
            .having(
              (state) => state.likedPlaylists.single.playlistId,
              'liked id',
              'pl_liked',
            ),
      ],
      verify: (_) {
        verify(() => getLiked(page: 1, limit: 20)).called(1);
      },
    );

    blocTest<LibraryCubit, LibraryState>(
      'loadLikedPlaylists clears liked playlists on failure',
      build: () {
        when(() => getLiked(page: 1, limit: 20)).thenThrow(
          Exception('liked failed'),
        );

        return buildCubit();
      },
      seed: () => LibraryState.initial().copyWith(
        likedPlaylists: [_playlist(id: 'old_liked', title: 'Old Liked')],
      ),
      act: (cubit) => cubit.loadLikedPlaylists(),
      expect: () => [
        isA<LibraryState>().having(
          (state) => state.isLoadingLikedPlaylists,
          'loading liked',
          isTrue,
        ),
        isA<LibraryState>()
            .having(
              (state) => state.isLoadingLikedPlaylists,
              'loading liked',
              isFalse,
            )
            .having(
              (state) => state.likedPlaylists,
              'liked playlists',
              isEmpty,
            )
            .having(
              (state) => state.errorMessage,
              'error',
              'Could not load liked playlists',
            ),
      ],
    );

    test('loadRecentPlaylists does not emit after close', () async {
      final remoteCompleter = Completer<List<PlaylistEntity>>();

      when(() => recentStore.load(limit: 10)).thenAnswer(
        (_) async => const <PlaylistEntity>[],
      );
      when(() => getRecent(limit: 10)).thenAnswer(
        (_) => remoteCompleter.future,
      );

      final cubit = buildCubit();
      final loadFuture = cubit.loadRecentPlaylists();

      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      remoteCompleter.complete(const <PlaylistEntity>[]);

      await expectLater(loadFuture, completes);
    });
  });
}

PlaylistEntity _playlist({
  required String id,
  required String title,
}) {
  return PlaylistEntity(
    playlistId: id,
    title: title,
    description: '',
    visibility: PlaylistVisibility.publicPlaylist,
    secretToken: null,
    coverImageUrl: null,
    owner: null,
    tracks: const [],
    tracksCount: 0,
    likesCount: 0,
  );
}
