import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
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
import 'package:soundcloud_clone/features/playlists/presentation/pages/playlist_detail_page.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

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
  group('PlaylistDetailPage owner actions', () {
    testWidgets('shows embed action for playlist owner', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          authUserId: 'owner-1',
          playlistOwnerId: 'owner-1',
        ),
      );

      expect(find.byTooltip('Get embed code'), findsOneWidget);
      expect(find.byTooltip('Share playlist'), findsOneWidget);
    });

    testWidgets('hides embed action for non-owner', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          authUserId: 'viewer-1',
          playlistOwnerId: 'owner-1',
        ),
      );

      expect(find.byTooltip('Get embed code'), findsNothing);
      expect(find.byTooltip('Share playlist'), findsOneWidget);
    });
  });
}

Widget _buildSubject({
  required String authUserId,
  required String playlistOwnerId,
}) {
  final authCubit = MockAuthCubit();
  when(() => authCubit.state).thenReturn(
    AuthAuthenticated(_user(id: authUserId)),
  );

  final playlistsCubit = _buildPlaylistsCubit();

  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<PlaylistsCubit>.value(value: playlistsCubit),
    ],
    child: MaterialApp(
      home: PlaylistDetailPage(
        playlistId: 'playlist-1',
        initialPlaylist: _playlist(ownerId: playlistOwnerId),
      ),
    ),
  );
}

PlaylistsCubit _buildPlaylistsCubit() {
  return PlaylistsCubit(
    getMyPlaylistsUseCase: MockGetMyPlaylistsUseCase(),
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

User _user({required String id}) {
  return User(
    id: id,
    email: '$id@example.com',
    displayName: 'User $id',
    handle: id,
    isVerified: true,
  );
}

PlaylistEntity _playlist({required String ownerId}) {
  return PlaylistEntity(
    playlistId: 'playlist-1',
    title: 'Late Night Drive',
    description: 'Chill tracks',
    visibility: PlaylistVisibility.publicPlaylist,
    secretToken: null,
    coverImageUrl: null,
    owner: PlaylistOwner(
      id: ownerId,
      displayName: 'Owner One',
    ),
    tracks: const [],
    tracksCount: 0,
    likesCount: 7,
  );
}
