import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';
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

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockOfflineCubit extends MockCubit<OfflineState>
    implements OfflineCubit {}

void main() {
  late MockPlaylistsCubit playlistsCubit;
  late MockPlayerCubit playerCubit;
  late MockAuthCubit authCubit;
  late MockOfflineCubit offlineCubit;

  setUpAll(() {
    registerFallbackValue(_track(id: 'fallback'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    playlistsCubit = MockPlaylistsCubit();
    playerCubit = MockPlayerCubit();
    authCubit = MockAuthCubit();
    offlineCubit = MockOfflineCubit();

    when(() => playerCubit.state).thenReturn(
      const PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.idle,
          position: Duration.zero,
        ),
      ),
    );
    when(() => authCubit.state).thenReturn(AuthUnauthenticated());
    when(() => offlineCubit.state).thenReturn(const OfflineState());
    when(() => offlineCubit.isDownloaded(any())).thenReturn(false);
  });

  tearDown(() async {
    if (getIt.isRegistered<PlayerCubit>()) {
      await getIt.unregister<PlayerCubit>();
    }
  });

  group('PlaylistDetailPage playback recording', () {
    testWidgets('loads details after first frame when no initial playlist',
        (tester) async {
      final state = PlaylistsState.initial();

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      when(() => playlistsCubit.loadPlaylistDetails('pl_1')).thenAnswer(
        (_) async {},
      );

      await tester.pumpWidget(
        _buildSubject(
          playlist: _playlist(),
          includeInitialPlaylist: false,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );
      await tester.pump();

      verify(() => playlistsCubit.loadPlaylistDetails('pl_1')).called(1);
      expect(find.text('Playlist not found'), findsOneWidget);
    });

    testWidgets('resolves secret playlist token after first frame',
        (tester) async {
      final state = PlaylistsState.initial();

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      when(() => playlistsCubit.resolveSecretPlaylist('token_1')).thenAnswer(
        (_) async {},
      );

      await tester.pumpWidget(
        _buildSubject(
          playlist: _playlist(),
          includeInitialPlaylist: false,
          secretToken: ' token_1 ',
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );
      await tester.pump();

      verify(() => playlistsCubit.resolveSecretPlaylist('token_1')).called(1);
    });

    testWidgets('shows loading indicator while details are loading',
        (tester) async {
      final state = PlaylistsState.initial().copyWith(
        isLoadingDetails: true,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      when(() => playlistsCubit.loadPlaylistDetails('pl_1')).thenAnswer(
        (_) async {},
      );

      await tester.pumpWidget(
        _buildSubject(
          playlist: _playlist(),
          includeInitialPlaylist: false,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

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

    testWidgets('plays a tapped track from its index', (tester) async {
      final playlist = _playlist(
        tracks: [_track(id: 'trk_1'), _track(id: 'trk_2')],
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
      when(() => playerCubit.playFromContext(
            tracks: playlist.tracks,
            startIndex: 1,
            source: 'playlist:pl_1',
          )).thenAnswer((_) async {});
      _registerPlayerFallback(playerCubit);

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );
      await tester.pumpAndSettle();

      final trackTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Track trk_2'),
          matching: find.byType(ListTile),
        ),
      );
      trackTile.onTap!();
      await tester.pumpAndSettle();

      verify(() => playerCubit.playFromContext(
            tracks: playlist.tracks,
            startIndex: 1,
            source: 'playlist:pl_1',
          )).called(1);
    });

    testWidgets('owner can add the current track to the playlist',
        (tester) async {
      final currentTrack = _track(id: 'trk_new');
      final playlist = _playlist(
        owner: const PlaylistOwner(id: 'user_1', displayName: 'Ali'),
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
      when(() => authCubit.state).thenReturn(AuthAuthenticated(_user()));
      when(() => playerCubit.state).thenReturn(
        PlayerUIState(
          playerState: const PlayerState(
            status: PlayerStatus.idle,
            position: Duration.zero,
          ),
          currentTrack: currentTrack,
        ),
      );
      when(() => playlistsCubit.addTrackToPlaylist(
            playlistId: 'pl_1',
            track: currentTrack,
          )).thenAnswer((_) async => true);
      _registerPlayerFallback(playerCubit);

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          authCubit: authCubit,
        ),
      );
      await tester.pumpAndSettle();

      final addButton =
          find.widgetWithText(OutlinedButton, 'Add current track');
      expect(addButton, findsOneWidget);

      await tester.ensureVisible(addButton);
      tester.widget<OutlinedButton>(addButton).onPressed!();
      await tester.pumpAndSettle();

      verify(() => playlistsCubit.addTrackToPlaylist(
            playlistId: 'pl_1',
            track: currentTrack,
          )).called(1);
    });

    testWidgets('owner add current track shows snack when there is no track',
        (tester) async {
      final playlist = _playlist(
        owner: const PlaylistOwner(id: 'user_1', displayName: 'Ali'),
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
      when(() => authCubit.state).thenReturn(AuthAuthenticated(_user()));

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          authCubit: authCubit,
        ),
      );
      await tester.pumpAndSettle();

      final addButton =
          find.widgetWithText(OutlinedButton, 'Add current track');
      await tester.ensureVisible(addButton);
      tester.widget<OutlinedButton>(addButton).onPressed!();
      await tester.pump();

      expect(find.text('No active track to add'), findsOneWidget);
    });

    testWidgets('owner add current track detects duplicates', (tester) async {
      final currentTrack = _track(id: 'trk_1');
      final playlist = _playlist(
        owner: const PlaylistOwner(id: 'user_1', displayName: 'Ali'),
        tracks: [currentTrack],
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
      when(() => authCubit.state).thenReturn(AuthAuthenticated(_user()));
      when(() => playerCubit.state).thenReturn(
        PlayerUIState(
          playerState: const PlayerState(
            status: PlayerStatus.idle,
            position: Duration.zero,
          ),
          currentTrack: currentTrack,
        ),
      );
      _registerPlayerFallback(playerCubit);

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          authCubit: authCubit,
        ),
      );
      await tester.pumpAndSettle();

      final addButton =
          find.widgetWithText(OutlinedButton, 'Add current track');
      await tester.ensureVisible(addButton);
      tester.widget<OutlinedButton>(addButton).onPressed!();
      await tester.pump();

      expect(find.text('Track is already in this playlist'), findsOneWidget);
      verifyNever(() => playlistsCubit.addTrackToPlaylist(
            playlistId: any(named: 'playlistId'),
            track: any(named: 'track'),
          ));
    });

    testWidgets('like button calls like action', (tester) async {
      final playlist = _playlist();
      final unlikedState = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: unlikedState,
      );
      when(() => playlistsCubit.state).thenReturn(unlikedState);
      when(() => playlistsCubit.likePlaylist('pl_1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );
      await tester.pumpAndSettle();

      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.favorite_border),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed!();
      await tester.pump();
      verify(() => playlistsCubit.likePlaylist('pl_1')).called(1);
    });

    testWidgets('liked playlist button calls unlike action', (tester) async {
      final likedPlaylist = _playlist().copyWith(isLiked: true);
      final likedState = PlaylistsState.initial().copyWith(
        selectedPlaylist: likedPlaylist,
      );
      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: likedState,
      );
      when(() => playlistsCubit.state).thenReturn(likedState);
      when(() => playlistsCubit.unlikePlaylist('pl_1'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildSubject(
          playlist: likedPlaylist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );
      await tester.pumpAndSettle();

      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.favorite),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed!();
      await tester.pump();
      verify(() => playlistsCubit.unlikePlaylist('pl_1')).called(1);
    });

    testWidgets('owner can remove a track from the playlist', (tester) async {
      final track = _track(id: 'trk_1');
      final playlist = _playlist(
        owner: const PlaylistOwner(id: 'user_1', displayName: 'Ali'),
        tracks: [track, _track(id: 'trk_2')],
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
      when(() => authCubit.state).thenReturn(AuthAuthenticated(_user()));
      when(() => playlistsCubit.removeTrackFromPlaylist(
            playlistId: 'pl_1',
            trackId: 'trk_1',
          )).thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          authCubit: authCubit,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pump();

      verify(() => playlistsCubit.removeTrackFromPlaylist(
            playlistId: 'pl_1',
            trackId: 'trk_1',
          )).called(1);
    });

    testWidgets('embed action opens embed code dialog', (tester) async {
      final playlist = _playlist(
        owner: const PlaylistOwner(id: 'user_1', displayName: 'Ali'),
      );
      final state = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
        embedCode: '<iframe src="playlist"></iframe>',
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      when(() => authCubit.state).thenReturn(AuthAuthenticated(_user()));
      when(() => playlistsCubit.loadEmbedCode('pl_1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          authCubit: authCubit,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Get embed code'));
      await tester.pumpAndSettle();

      expect(find.text('Embed code'), findsOneWidget);
      expect(find.text('<iframe src="playlist"></iframe>'), findsOneWidget);
    });

    testWidgets('offline track and playlist downloads call OfflineCubit',
        (tester) async {
      final track = _track(id: 'trk_1');
      final playlist = _playlist(tracks: [track]);
      final state = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      whenListen(
        offlineCubit,
        const Stream<OfflineState>.empty(),
        initialState: const OfflineState(),
      );
      when(() => offlineCubit.state).thenReturn(const OfflineState());
      when(() => offlineCubit.downloadTrack(track)).thenAnswer((_) async {});
      when(() => offlineCubit.saveDownloadedPlaylist(playlist))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          offlineCubit: offlineCubit,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Download track'));
      await tester.pump();
      verify(() => offlineCubit.downloadTrack(track)).called(1);

      final downloadPlaylist =
          find.widgetWithText(OutlinedButton, 'Download playlist');
      await tester.ensureVisible(downloadPlaylist);
      await tester.tap(downloadPlaylist);
      await tester.pumpAndSettle();

      verify(() => offlineCubit.saveDownloadedPlaylist(playlist)).called(1);
    });

    testWidgets('feedback listener shows snackbars and clears feedback',
        (tester) async {
      final playlist = _playlist();
      final errorState = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
        errorMessage: 'Playlist exploded',
      );
      final infoState = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
        infoMessage: 'Playlist saved',
      );

      whenListen(
        playlistsCubit,
        Stream<PlaylistsState>.fromIterable([errorState, infoState]),
        initialState: PlaylistsState.initial().copyWith(
          selectedPlaylist: playlist,
        ),
      );
      when(() => playlistsCubit.state).thenReturn(
        PlaylistsState.initial().copyWith(selectedPlaylist: playlist),
      );
      when(() => playlistsCubit.clearFeedback()).thenReturn(null);

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Playlist saved'), findsOneWidget);
      verify(() => playlistsCubit.clearFeedback()).called(2);
    });

    testWidgets('secret playlist can copy its secret link', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });
      final playlist = _playlist().copyWith(
        visibility: PlaylistVisibility.privatePlaylist,
        secretToken: 'secret_token',
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

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
        ),
      );
      await tester.pump();

      final copyButton =
          find.widgetWithText(OutlinedButton, 'Copy secret link');
      await tester.ensureVisible(copyButton);
      await tester.tap(copyButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Secret link copied'), findsOneWidget);
    });

    testWidgets('owner can cancel and confirm playlist deletion',
        (tester) async {
      final playlist = _playlist(
        owner: const PlaylistOwner(id: 'user_1', displayName: 'Ali'),
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
      when(() => authCubit.state).thenReturn(AuthAuthenticated(_user()));
      when(() => playlistsCubit.deletePlaylist('pl_1')).thenAnswer(
        (_) async {},
      );

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          authCubit: authCubit,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete playlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => playlistsCubit.deletePlaylist(any()));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete playlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => playlistsCubit.deletePlaylist('pl_1')).called(1);
    });

    testWidgets('owner reorder delegates the reordered track list',
        (tester) async {
      final first = _track(id: 'trk_1');
      final second = _track(id: 'trk_2');
      final playlist = _playlist(
        owner: const PlaylistOwner(id: 'user_1', displayName: 'Ali'),
        tracks: [first, second],
      );
      final state = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
        hasMorePlaylistTracks: false,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      when(() => authCubit.state).thenReturn(AuthAuthenticated(_user()));
      when(() => playlistsCubit.reorderTracks(
            playlistId: any(named: 'playlistId'),
            orderedTracks: any(named: 'orderedTracks'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          authCubit: authCubit,
        ),
      );
      await tester.pumpAndSettle();

      tester
          .widget<ReorderableListView>(find.byType(ReorderableListView))
          .onReorder(0, 2);

      final captured = verify(() => playlistsCubit.reorderTracks(
            playlistId: 'pl_1',
            orderedTracks: captureAny(named: 'orderedTracks'),
          )).captured.single as List<Track>;
      expect(captured.map((track) => track.id), ['trk_2', 'trk_1']);
    });

    testWidgets('track download shows already downloaded state',
        (tester) async {
      final track = _track(id: 'trk_1');
      final playlist = _playlist(tracks: [track]);
      final state = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      whenListen(
        offlineCubit,
        const Stream<OfflineState>.empty(),
        initialState: OfflineState(
          downloadedTracks: {'trk_1': '/offline/trk_1.mp3'},
        ),
      );
      when(() => offlineCubit.state).thenReturn(
        OfflineState(downloadedTracks: {'trk_1': '/offline/trk_1.mp3'}),
      );
      when(() => offlineCubit.isDownloaded('trk_1')).thenReturn(true);

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          offlineCubit: offlineCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Track downloaded'), findsOneWidget);
    });

    testWidgets('track download failure shows snackbar', (tester) async {
      final track = _track(id: 'trk_1');
      final playlist = _playlist(tracks: [track]);
      final state = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      whenListen(
        offlineCubit,
        const Stream<OfflineState>.empty(),
        initialState: const OfflineState(),
      );
      when(() => offlineCubit.state).thenReturn(const OfflineState());
      when(() => offlineCubit.isDownloaded('trk_1')).thenReturn(false);
      when(() => offlineCubit.downloadTrack(track)).thenThrow(
        Exception('boom'),
      );

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          offlineCubit: offlineCubit,
        ),
      );
      await tester.pumpAndSettle();

      final downloadTrack =
          find.byIcon(Icons.download_for_offline_outlined).last;
      await tester.ensureVisible(downloadTrack);
      await tester.tap(downloadTrack);
      await tester.pump();

      expect(find.text('Track download failed'), findsOneWidget);
    });

    testWidgets('playlist download handles already-downloaded playlists',
        (tester) async {
      final track = _track(id: 'trk_1');
      final playlist = _playlist(tracks: [track]);
      final state = PlaylistsState.initial().copyWith(
        selectedPlaylist: playlist,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      whenListen(
        offlineCubit,
        const Stream<OfflineState>.empty(),
        initialState: OfflineState(
          downloadedTracks: {'trk_1': '/offline/trk_1.mp3'},
        ),
      );
      when(() => offlineCubit.state).thenReturn(
        OfflineState(downloadedTracks: {'trk_1': '/offline/trk_1.mp3'}),
      );
      when(() => offlineCubit.isDownloaded('trk_1')).thenReturn(true);
      when(() => offlineCubit.saveDownloadedPlaylist(playlist))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildSubject(
          playlist: playlist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          offlineCubit: offlineCubit,
        ),
      );
      await tester.pumpAndSettle();

      final downloadPlaylist =
          find.widgetWithText(OutlinedButton, 'Playlist downloaded');
      await tester.ensureVisible(downloadPlaylist);
      await tester.tap(downloadPlaylist);
      await tester.pump();

      verify(() => offlineCubit.saveDownloadedPlaylist(playlist)).called(1);
      expect(find.text('Playlist already downloaded'), findsOneWidget);
    });

    testWidgets('non-owner can copy playlist as-is', (tester) async {
      final track = _track(id: 'trk_1');
      final sourcePlaylist = _playlist(
        owner: const PlaylistOwner(id: 'other_user', displayName: 'Mona'),
        tracks: [track],
      ).copyWith(
        genre: 'Rock',
      );

      final copiedPlaylist = _playlist(
        owner: null,
        tracks: const <Track>[],
      ).copyWith(
        playlistId: 'pl_copy',
        title: sourcePlaylist.title,
        description: sourcePlaylist.description,
        genre: sourcePlaylist.genre,
        coverImageUrl: null,
      );

      final state = PlaylistsState.initial().copyWith(
        selectedPlaylist: sourcePlaylist,
      );

      whenListen(
        playlistsCubit,
        const Stream<PlaylistsState>.empty(),
        initialState: state,
      );
      when(() => playlistsCubit.state).thenReturn(state);
      when(() => authCubit.state).thenReturn(AuthAuthenticated(_user()));

      when(
        () => playlistsCubit.createPlaylist(
          title: 'Focus Playlist',
          description: 'Coding tracks',
          visibility: PlaylistVisibility.publicPlaylist,
          genre: 'Rock',
          coverImagePath: null,
          initialTrackIds: any<List<String>>(named: 'initialTrackIds'),
        ),
      ).thenAnswer((_) async => copiedPlaylist);

      await tester.pumpWidget(
        _buildRoutedSubject(
          playlist: sourcePlaylist,
          playlistsCubit: playlistsCubit,
          playerCubit: playerCubit,
          authCubit: authCubit,
        ),
      );
      await tester.pump();

      final copyButton = find.widgetWithText(OutlinedButton, 'Copy playlist');
      await tester.ensureVisible(copyButton);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save as is'));
      await tester.pumpAndSettle();

      final capturedTrackIds = verify(
        () => playlistsCubit.createPlaylist(
          title: 'Focus Playlist',
          description: 'Coding tracks',
          visibility: PlaylistVisibility.publicPlaylist,
          genre: 'Rock',
          coverImagePath: null,
          initialTrackIds: captureAny<List<String>>(named: 'initialTrackIds'),
        ),
      ).captured.single as List<String>;

      expect(capturedTrackIds, ['trk_1']);
    });
  });
}

Widget _buildSubject({
  required PlaylistEntity playlist,
  PlaylistEntity? initialPlaylist,
  bool includeInitialPlaylist = true,
  String? secretToken,
  required PlaylistsCubit playlistsCubit,
  required PlayerCubit playerCubit,
  AuthCubit? authCubit,
  OfflineCubit? offlineCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<PlaylistsCubit>.value(value: playlistsCubit),
      BlocProvider<PlayerCubit>.value(value: playerCubit),
      if (authCubit != null) BlocProvider<AuthCubit>.value(value: authCubit),
      if (offlineCubit != null)
        BlocProvider<OfflineCubit>.value(value: offlineCubit),
    ],
    child: MaterialApp(
      home: PlaylistDetailPage(
        playlistId: playlist.playlistId,
        secretToken: secretToken,
        initialPlaylist:
            includeInitialPlaylist ? (initialPlaylist ?? playlist) : null,
      ),
    ),
  );
}

Widget _buildRoutedSubject({
  required PlaylistEntity playlist,
  required PlaylistsCubit playlistsCubit,
  required PlayerCubit playerCubit,
  AuthCubit? authCubit,
  OfflineCubit? offlineCubit,
}) {
  final router = GoRouter(
    initialLocation: '/playlist/${playlist.playlistId}',
    routes: [
      GoRoute(
        path: '/playlist/:id',
        builder: (context, state) {
          final extraPlaylist = state.extra is PlaylistEntity
              ? state.extra! as PlaylistEntity
              : playlist;
          return PlaylistDetailPage(
            playlistId: state.pathParameters['id']!,
            initialPlaylist: extraPlaylist,
          );
        },
      ),
    ],
  );

  return MultiBlocProvider(
    providers: [
      BlocProvider<PlaylistsCubit>.value(value: playlistsCubit),
      BlocProvider<PlayerCubit>.value(value: playerCubit),
      if (authCubit != null) BlocProvider<AuthCubit>.value(value: authCubit),
      if (offlineCubit != null)
        BlocProvider<OfflineCubit>.value(value: offlineCubit),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

PlaylistEntity _playlist({
  List<Track> tracks = const <Track>[],
  int? tracksCount,
  PlaylistOwner? owner,
}) {
  return PlaylistEntity(
    playlistId: 'pl_1',
    title: 'Focus Playlist',
    description: 'Coding tracks',
    visibility: PlaylistVisibility.publicPlaylist,
    secretToken: null,
    coverImageUrl: null,
    owner: owner,
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

User _user() {
  return const User(
    id: 'user_1',
    email: 'ali@example.com',
    displayName: 'Ali',
    handle: 'ali',
    isVerified: true,
  );
}

void _registerPlayerFallback(PlayerCubit playerCubit) {
  if (getIt.isRegistered<PlayerCubit>()) return;
  getIt.registerSingleton<PlayerCubit>(playerCubit);
}
