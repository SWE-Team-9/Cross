import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/library/presentation/pages/downloaded_items_page.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class MockOfflineCubit extends MockCubit<OfflineState>
    implements OfflineCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOfflineCubit offlineCubit;

  setUp(() {
    offlineCubit = MockOfflineCubit();
    GetIt.I.registerSingleton<OfflineCubit>(offlineCubit);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('DownloadedTracksPage', () {
    testWidgets('shows empty state when no tracks are downloaded',
        (tester) async {
      whenListen(
        offlineCubit,
        const Stream<OfflineState>.empty(),
        initialState: const OfflineState(),
      );
      when(() => offlineCubit.state).thenReturn(const OfflineState());

      await tester.pumpWidget(const MaterialApp(home: DownloadedTracksPage()));

      expect(find.text('Downloaded tracks'), findsOneWidget);
      expect(find.text('No downloaded tracks yet'), findsOneWidget);
    });

    testWidgets('shows saved track details and fallback downloaded tracks',
        (tester) async {
      const state = OfflineState(
        downloadedTracks: {
          'trk_saved': '/music/saved.mp3',
          'trk_fallback': '/music/fallback.mp3',
        },
        downloadedTrackDetails: {
          'trk_saved': Track(
            id: 'trk_saved',
            title: 'Saved Detail',
            artist: 'Saved Artist',
            audioUrl: '',
            localPath: '/music/saved.mp3',
          ),
        },
      );
      whenListen(
        offlineCubit,
        const Stream<OfflineState>.empty(),
        initialState: state,
      );
      when(() => offlineCubit.state).thenReturn(state);

      await tester.pumpWidget(const MaterialApp(home: DownloadedTracksPage()));

      expect(find.text('Saved Detail'), findsOneWidget);
      expect(find.text('Saved Artist'), findsOneWidget);
      expect(find.text('trk_fallback'), findsOneWidget);
      expect(find.text('Downloaded track'), findsOneWidget);
    });
  });

  group('DownloadedPlaylistsPage', () {
    testWidgets('shows empty state when no playlists are downloaded',
        (tester) async {
      whenListen(
        offlineCubit,
        const Stream<OfflineState>.empty(),
        initialState: const OfflineState(),
      );
      when(() => offlineCubit.state).thenReturn(const OfflineState());

      await tester.pumpWidget(
        const MaterialApp(home: DownloadedPlaylistsPage()),
      );

      expect(find.text('Downloaded playlists'), findsOneWidget);
      expect(find.text('No downloaded playlists yet'), findsOneWidget);
    });

    testWidgets('shows downloaded playlists with track counts', (tester) async {
      final state = OfflineState(
        downloadedPlaylists: {
          'pl_1': _playlist(),
        },
      );
      whenListen(
        offlineCubit,
        const Stream<OfflineState>.empty(),
        initialState: state,
      );
      when(() => offlineCubit.state).thenReturn(state);

      await tester.pumpWidget(
        const MaterialApp(home: DownloadedPlaylistsPage()),
      );

      expect(find.text('Offline Playlist'), findsOneWidget);
      expect(find.text('2 downloaded tracks'), findsOneWidget);
    });
  });
}

PlaylistEntity _playlist() {
  return const PlaylistEntity(
    playlistId: 'pl_1',
    title: 'Offline Playlist',
    description: '',
    visibility: PlaylistVisibility.publicPlaylist,
    secretToken: null,
    coverImageUrl: null,
    owner: null,
    tracks: [
      Track(id: 'trk_1', title: 'One', artist: 'Artist', audioUrl: ''),
      Track(id: 'trk_2', title: 'Two', artist: 'Artist', audioUrl: ''),
    ],
    tracksCount: 2,
    likesCount: 0,
  );
}
