import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_cubit.dart';
import 'package:soundcloud_clone/features/playlists/presentation/bloc/playlists_state.dart';

class MockPlaylistsCubit extends MockCubit<PlaylistsState>
    implements PlaylistsCubit {}

PlaylistEntity _playlist({
  required String id,
  required String title,
  List<Track> tracks = const <Track>[],
}) {
  return PlaylistEntity(
    playlistId: id,
    title: title,
    description: 'desc',
    visibility: PlaylistVisibility.publicPlaylist,
    secretToken: null,
    owner: null,
    tracks: tracks,
    tracksCount: tracks.length,
  );
}

void main() {
  late MockPlaylistsCubit playlistsCubit;

  const track = Track(
    id: 'coverage-track-1',
    title: 'Song 1',
    artist: 'Ali',
    audioUrl: 'https://example.com/audio.mp3',
  );

  Widget buildHost({
    required String buttonLabel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () => AddToPlaylistSheet.show(context, track: track),
                child: Text(buttonLabel),
              ),
            );
          },
        ),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(track);
    registerFallbackValue(PlaylistVisibility.publicPlaylist);
  });

  setUp(() async {
    await getIt.reset();

    playlistsCubit = MockPlaylistsCubit();

    final seeded = PlaylistsState.initial().copyWith(
      playlists: [
        _playlist(
          id: 'pl_1',
          title: 'My Favourites',
          tracks: const <Track>[],
        ),
        _playlist(
          id: 'pl_2',
          title: 'Chill Vibes',
          tracks: const <Track>[
            track,
          ],
        ),
      ],
    );

    when(() => playlistsCubit.state).thenReturn(seeded);
    when(() => playlistsCubit.stream)
        .thenAnswer((_) => const Stream<PlaylistsState>.empty());
    when(() => playlistsCubit.loadMyPlaylists()).thenAnswer((_) async {});
    when(() => playlistsCubit.clearFeedback()).thenReturn(null);
    when(
      () => playlistsCubit.addTrackToPlaylist(
        playlistId: any(named: 'playlistId'),
        track: any(named: 'track'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => playlistsCubit.createPlaylist(
        title: 'Coverage Playlist',
        description: '',
        visibility: PlaylistVisibility.publicPlaylist,
      ),
    ).thenAnswer(
      (_) async => _playlist(id: 'pl_new', title: 'Coverage Playlist'),
    );

    getIt.registerFactory<PlaylistsCubit>(() => playlistsCubit);
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('AddToPlaylistSheet', () {
    testWidgets('renders default playlists', (tester) async {
      await tester.pumpWidget(
        buildHost(buttonLabel: 'open sheet'),
      );

      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Add to playlist'), findsOneWidget);
      expect(find.text('My Favourites'), findsOneWidget);
      expect(find.text('Chill Vibes'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      verify(() => playlistsCubit.loadMyPlaylists()).called(1);
    });

    testWidgets('adds track to existing playlist and shows snackbar',
        (tester) async {
      await tester.pumpWidget(
        buildHost(buttonLabel: 'open existing'),
      );

      await tester.tap(find.text('open existing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Favourites'));
      await tester.pumpAndSettle();

      expect(find.text('Added to My Favourites'), findsOneWidget);
      verify(
        () => playlistsCubit.addTrackToPlaylist(
          playlistId: 'pl_1',
          track: track,
        ),
      ).called(1);

      await tester.tap(find.text('open existing'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('creates a new playlist and adds the track', (tester) async {
      await tester.pumpWidget(
        buildHost(buttonLabel: 'open create'),
      );

      await tester.tap(find.text('open create'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();

      final titleField = find.byWidgetPredicate(
        (widget) =>
        widget is TextField && widget.decoration?.labelText == 'Title',
      );
      await tester.enterText(titleField, 'Coverage Playlist');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Created "Coverage Playlist" and added track'),
          findsOneWidget);
      verify(
        () => playlistsCubit.createPlaylist(
          title: 'Coverage Playlist',
          description: '',
          visibility: PlaylistVisibility.publicPlaylist,
        ),
      ).called(1);
      verify(
        () => playlistsCubit.addTrackToPlaylist(
          playlistId: 'pl_new',
          track: track,
        ),
      ).called(1);

      await tester.tap(find.text('open create'));
      await tester.pumpAndSettle();
      expect(find.text('Add to playlist'), findsOneWidget);
    });
  });
}
