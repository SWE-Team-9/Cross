import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/add_track_to_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/create_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/delete_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_my_playlists_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_playlist_details_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_playlist_embed_code_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/remove_track_from_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/reorder_playlist_tracks_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/resolve_secret_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/update_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_cubit.dart';
import 'package:soundcloud_clone/features/playlists/presentation/pages/playlists_page.dart';

class MockGetMyPlaylistsUseCase extends Mock implements GetMyPlaylistsUseCase {}

class MockCreatePlaylistUseCase extends Mock implements CreatePlaylistUseCase {}

class MockGetPlaylistDetailsUseCase extends Mock
    implements GetPlaylistDetailsUseCase {}

class MockUpdatePlaylistUseCase extends Mock implements UpdatePlaylistUseCase {}

class MockDeletePlaylistUseCase extends Mock implements DeletePlaylistUseCase {}

class MockAddTrackToPlaylistUseCase extends Mock
    implements AddTrackToPlaylistUseCase {}

class MockRemoveTrackFromPlaylistUseCase extends Mock
    implements RemoveTrackFromPlaylistUseCase {}

class MockReorderPlaylistTracksUseCase extends Mock
    implements ReorderPlaylistTracksUseCase {}

class MockResolveSecretPlaylistUseCase extends Mock
    implements ResolveSecretPlaylistUseCase {}

class MockGetPlaylistEmbedCodeUseCase extends Mock
    implements GetPlaylistEmbedCodeUseCase {}

void main() {
  group('PlaylistsPage pagination', () {
    testWidgets('loads more playlists when scrolled near bottom',
        (tester) async {
      final getMy = MockGetMyPlaylistsUseCase();

      when(() => getMy(page: 1, limit: 20)).thenAnswer(
        (_) async => List<PlaylistEntity>.generate(
          20,
          (index) => _playlist(id: 'pl_$index', title: 'Playlist $index'),
        ),
      );

      when(() => getMy(page: 2, limit: 20)).thenAnswer(
        (_) async => <PlaylistEntity>[
          _playlist(id: 'pl_20', title: 'Playlist 20'),
        ],
      );

      final cubit = _buildCubit(getMy: getMy);

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.pumpAndSettle();

      expect(find.text('Playlist 0'), findsOneWidget);
      expect(find.text('Playlist 19'), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, -1600));
      await tester.pumpAndSettle();

      verify(() => getMy(page: 2, limit: 20)).called(1);
      expect(find.text('Playlist 20'), findsOneWidget);
      expect(cubit.state.playlists.length, 21);

      await cubit.close();
    });

    testWidgets('shows bottom loader while loading more playlists',
        (tester) async {
      final getMy = MockGetMyPlaylistsUseCase();
      final pageTwoCompleter = Completer<List<PlaylistEntity>>();

      when(() => getMy(page: 1, limit: 20)).thenAnswer(
        (_) async => List<PlaylistEntity>.generate(
          20,
          (index) => _playlist(id: 'pl_$index', title: 'Playlist $index'),
        ),
      );

      when(() => getMy(page: 2, limit: 20)).thenAnswer(
        (_) => pageTwoCompleter.future,
      );

      final cubit = _buildCubit(getMy: getMy);

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -1600));
      await tester.pump();

      expect(cubit.state.isLoadingMoreMyPlaylists, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pageTwoCompleter.complete(
        <PlaylistEntity>[_playlist(id: 'pl_20', title: 'Playlist 20')],
      );

      await tester.pumpAndSettle();

      expect(cubit.state.isLoadingMoreMyPlaylists, isFalse);
      expect(find.text('Playlist 20'), findsOneWidget);

      await cubit.close();
    });
  });
}

Widget _buildSubject(PlaylistsCubit cubit) {
  return MaterialApp(
    home: BlocProvider<PlaylistsCubit>.value(
      value: cubit,
      child: const PlaylistsPage(),
    ),
  );
}

PlaylistsCubit _buildCubit({
  required GetMyPlaylistsUseCase getMy,
}) {
  return PlaylistsCubit(
    getMyPlaylistsUseCase: getMy,
    createPlaylistUseCase: MockCreatePlaylistUseCase(),
    getPlaylistDetailsUseCase: MockGetPlaylistDetailsUseCase(),
    updatePlaylistUseCase: MockUpdatePlaylistUseCase(),
    deletePlaylistUseCase: MockDeletePlaylistUseCase(),
    addTrackToPlaylistUseCase: MockAddTrackToPlaylistUseCase(),
    removeTrackFromPlaylistUseCase: MockRemoveTrackFromPlaylistUseCase(),
    reorderPlaylistTracksUseCase: MockReorderPlaylistTracksUseCase(),
    resolveSecretPlaylistUseCase: MockResolveSecretPlaylistUseCase(),
    getPlaylistEmbedCodeUseCase: MockGetPlaylistEmbedCodeUseCase(),
  );
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
