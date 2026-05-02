import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_cubit.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_state.dart';
import 'package:soundcloud_clone/features/playlists/presentation/pages/playlist_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPlaylistsCubit extends MockCubit<PlaylistsState>
    implements PlaylistsCubit {}

class MockPlayerCubit extends Mock implements PlayerCubit {}

void main() {
  late MockPlaylistsCubit playlistsCubit;
  late MockPlayerCubit playerCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    playlistsCubit = MockPlaylistsCubit();
    playerCubit = MockPlayerCubit();

    when(() => playerCubit.state).thenReturn(
      const PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.idle,
          position: Duration.zero,
        ),
      ),
    );
  });

  group('PlaylistDetailPage playback recording', () {
    testWidgets('records playlist playback when play playlist is tapped',
        (tester) async {
      final playlist = _playlist(
        tracks: [_track(id: 'trk_1')],
      );
      final state = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      when(() => playlistsCubit.recordPlaylistPlayback('pl_1')).thenAnswer(
        (_) async {},
      );

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );
      await tester.pumpAndSettle();

      final playButton = find.widgetWithText(OutlinedButton, 'Play playlist');
      expect(playButton, findsOneWidget);

      await tester.ensureVisible(playButton);
      await tester.tap(playButton);
      await tester.pumpAndSettle();
      verify(() => playlistsCubit.recordPlaylistPlayback('pl_1')).called(1);
    });

    testWidgets('does not record playback when playlist has no tracks',
        (tester) async {
      final playlist = _playlist();
      final state = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No tracks in this playlist yet'), findsOneWidget);

      final playButton = find.widgetWithText(OutlinedButton, 'Play playlist');
      expect(playButton, findsOneWidget);

      await tester.ensureVisible(playButton);
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      verifyNever(() => playlistsCubit.recordPlaylistPlayback(any()));
    });

    testWidgets('shows load more tracks and requests next page on tap',
        (tester) async {
      final playlist = _playlist(
        tracks: [_track(id: 'trk_1'), _track(id: 'trk_2')],
        tracksCount: 5,
      );
      final state = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
        playlistTracksOffset: 2,
        hasMorePlaylistTracks: true,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      when(() => playlistsCubit.loadMorePlaylistTracks()).thenAnswer(
        (_) async {},
      );

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );
      await tester.pumpAndSettle();

      final loadMoreButton =
          find.widgetWithText(OutlinedButton, 'Load more tracks');
      expect(loadMoreButton, findsOneWidget);

      await tester.ensureVisible(loadMoreButton);
      await tester.tap(loadMoreButton);
      await tester.pumpAndSettle();

      verify(() => playlistsCubit.loadMorePlaylistTracks()).called(1);
    });
  });
}

Widget _buildSubject({
  required PlaylistEntity playlist,
  required PlaylistsCubit playlistsCubit,
  required PlayerCubit playerCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<PlaylistsCubit>.value(value: playlistsCubit),
      BlocProvider<PlayerCubit>.value(value: playerCubit),
    ],
    child: MaterialApp(
      home: PlaylistDetailPage(
        playlistId: playlist.playlistId,
        initialPlaylist: playlist,
      ),
    ),
  );
}

PlaylistEntity _playlist({
  List<Track> tracks = const <Track>[],
  int? tracksCount,
}) {
  return PlaylistEntity(
    playlistId: 'pl_1',
    title: 'Focus Playlist',
    description: 'Coding tracks',
    visibility: PlaylistVisibility.publicPlaylist,
    secretToken: null,
    coverImageUrl: null,
    owner: null,
    tracks: tracks,
    tracksCount: tracksCount ?? tracks.length,
    likesCount: 0,
  );
}

Track _track({required String id}) {
  return Track(
    id: id,
    title: 'Track $id',
    artist: 'Artist',
    audioUrl: 'https://cdn.example/$id.mp3',
  );
}
