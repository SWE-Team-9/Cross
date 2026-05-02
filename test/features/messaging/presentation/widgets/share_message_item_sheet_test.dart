import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/get_my_liked_tracks_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/share_message_item_sheet.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';

class MockDioClient extends Mock implements DioClient {}

class MockPlaylistsRepository extends Mock implements PlaylistsRepository {}

class MockGetMyLikedTracksUseCase extends Mock
    implements GetMyLikedTracksUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDioClient dioClient;
  late MockPlaylistsRepository playlistsRepository;
  late MockGetMyLikedTracksUseCase likedTracksUseCase;
  late List<Track> sharedTracks;
  late List<PlaylistEntity> sharedPlaylists;

  setUp(() async {
    await GetIt.I.reset();
    dioClient = MockDioClient();
    playlistsRepository = MockPlaylistsRepository();
    likedTracksUseCase = MockGetMyLikedTracksUseCase();
    sharedTracks = <Track>[];
    sharedPlaylists = <PlaylistEntity>[];

    GetIt.I.registerSingleton<DioClient>(dioClient);
    GetIt.I.registerSingleton<PlaylistsRepository>(playlistsRepository);
    GetIt.I.registerSingleton<GetMyLikedTracksUseCase>(likedTracksUseCase);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('ShareMessageItemSheet', () {
    testWidgets('loads my tracks, filters them, and shares the selected track',
        (tester) async {
      _stubMyTracks(dioClient, [
        <String, dynamic>{
          'id': 'trk_1',
          'title': 'Studio Track',
          'artistName': 'Nada',
          'streamUrl': 'https://cdn.example/trk_1.mp3',
          'coverArtUrl': '',
          'artistHandle': 'nada',
          'artistId': 'artist_1',
          'likesCount': '8',
          'repostsCount': 2,
          'durationMs': 120000,
        },
        <String, dynamic>{
          'id': 'trk_2',
          'title': 'Live Cut',
          'artistName': 'Omar',
        },
      ]);

      await tester.pumpWidget(_buildSubject(
        onShareTrack: sharedTracks.add,
        onSharePlaylist: sharedPlaylists.add,
      ));
      await tester.tap(find.text('Open share sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Studio Track'), findsOneWidget);
      expect(find.text('Live Cut'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'studio');
      await tester.pumpAndSettle();

      expect(find.text('Studio Track'), findsOneWidget);
      expect(find.text('Live Cut'), findsNothing);

      await tester.tap(find.text('Studio Track'));
      await tester.pumpAndSettle();

      expect(sharedTracks, hasLength(1));
      expect(sharedTracks.single.id, 'trk_1');
      expect(sharedTracks.single.artist, 'Nada');
      expect(sharedPlaylists, isEmpty);
    });

    testWidgets('shows empty state when track search has no matches',
        (tester) async {
      _stubMyTracks(dioClient, [
        <String, dynamic>{
          'id': 'trk_1',
          'title': 'Studio Track',
          'artistName': 'Nada',
        },
      ]);

      await tester.pumpWidget(_buildSubject(
        onShareTrack: sharedTracks.add,
        onSharePlaylist: sharedPlaylists.add,
      ));
      await tester.tap(find.text('Open share sheet'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pumpAndSettle();

      expect(find.text('No tracks found'), findsOneWidget);
    });

    testWidgets('loads liked tracks through the use case', (tester) async {
      _stubMyTracks(dioClient, const <Map<String, dynamic>>[]);
      when(() => likedTracksUseCase()).thenAnswer(
        (_) async => const [
          ManagedTrack(
            id: 'liked_1',
            title: 'Liked Track',
            artistHandle: 'liked_artist',
            visibility: TrackManagementVisibility.publicTrack,
            artworkUrl: 'https://cdn.example/liked.jpg',
            durationInSeconds: 42,
            likesCount: 9,
            repostsCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(_buildSubject(
        onShareTrack: sharedTracks.add,
        onSharePlaylist: sharedPlaylists.add,
      ));
      await tester.tap(find.text('Open share sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Liked'));
      await tester.pumpAndSettle();

      expect(find.text('Liked Track'), findsOneWidget);
      expect(find.text('liked_artist'), findsOneWidget);

      await tester.tap(find.text('Liked Track'));
      await tester.pumpAndSettle();

      expect(sharedTracks.single.id, 'liked_1');
      expect(sharedTracks.single.artist, 'liked_artist');
      expect(sharedTracks.single.durationMs, 42000);
    });

    testWidgets('loads my playlists and shares the selected playlist',
        (tester) async {
      _stubMyTracks(dioClient, const <Map<String, dynamic>>[]);
      when(() => playlistsRepository.getMyPlaylists(limit: 100)).thenAnswer(
        (_) async => [
          _playlist(
            'pl_1',
            title: 'Writing Queue',
            owner: const PlaylistOwner(id: 'owner_1', displayName: 'Salma'),
          ),
          _playlist('pl_2', title: 'Gym List'),
        ],
      );

      await tester.pumpWidget(_buildSubject(
        onShareTrack: sharedTracks.add,
        onSharePlaylist: sharedPlaylists.add,
      ));
      await tester.tap(find.text('Open share sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Playlists'));
      await tester.pumpAndSettle();

      expect(find.text('Writing Queue'), findsOneWidget);
      expect(find.text('Salma'), findsOneWidget);
      expect(find.text('Gym List'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'writing');
      await tester.pumpAndSettle();

      expect(find.text('Writing Queue'), findsOneWidget);
      expect(find.text('Gym List'), findsNothing);

      await tester.tap(find.text('Writing Queue'));
      await tester.pumpAndSettle();

      expect(sharedTracks, isEmpty);
      expect(sharedPlaylists.single.playlistId, 'pl_1');
    });

    testWidgets('loads liked playlists and shows track count fallback',
        (tester) async {
      _stubMyTracks(dioClient, const <Map<String, dynamic>>[]);
      when(() => playlistsRepository.getLikedPlaylists(limit: 100)).thenAnswer(
        (_) async => [
          _playlist('liked_pl', title: 'Liked Playlist', tracksCount: 7),
        ],
      );

      await tester.pumpWidget(_buildSubject(
        onShareTrack: sharedTracks.add,
        onSharePlaylist: sharedPlaylists.add,
      ));
      await tester.tap(find.text('Open share sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Playlists'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Liked'));
      await tester.pumpAndSettle();

      expect(find.text('Liked Playlist'), findsOneWidget);
      expect(find.text('7 tracks'), findsOneWidget);
    });

    testWidgets('shows playlist empty state when no playlists match',
        (tester) async {
      _stubMyTracks(dioClient, const <Map<String, dynamic>>[]);
      when(() => playlistsRepository.getMyPlaylists(limit: 100)).thenAnswer(
        (_) async => [_playlist('pl_1', title: 'Morning')],
      );

      await tester.pumpWidget(_buildSubject(
        onShareTrack: sharedTracks.add,
        onSharePlaylist: sharedPlaylists.add,
      ));
      await tester.tap(find.text('Open share sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Playlists'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'night');
      await tester.pumpAndSettle();

      expect(find.text('No playlists found'), findsOneWidget);
    });

    testWidgets('shows error state when loading fails', (tester) async {
      when(() => dioClient.get(ApiConstants.currentUser))
          .thenThrow(Exception('boom'));

      await tester.pumpWidget(_buildSubject(
        onShareTrack: sharedTracks.add,
        onSharePlaylist: sharedPlaylists.add,
      ));
      await tester.tap(find.text('Open share sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load items'), findsOneWidget);
    });
  });
}

Widget _buildSubject({
  required void Function(Track track) onShareTrack,
  required void Function(PlaylistEntity playlist) onSharePlaylist,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                ShareMessageItemSheet.show(
                  context,
                  onShareTrack: (track) async => onShareTrack(track),
                  onSharePlaylist: (playlist) async =>
                      onSharePlaylist(playlist),
                );
              },
              child: const Text('Open share sheet'),
            ),
          );
        },
      ),
    ),
  );
}

void _stubMyTracks(
  MockDioClient dioClient,
  List<Map<String, dynamic>> tracks,
) {
  when(() => dioClient.get(ApiConstants.currentUser)).thenAnswer(
    (_) async => Response<dynamic>(
      requestOptions: RequestOptions(path: ApiConstants.currentUser),
      data: const <String, dynamic>{
        'data': <String, dynamic>{'id': 'user_1'},
      },
    ),
  );
  when(() => dioClient.get(
        ApiConstants.userTracksPath('user_1'),
        queryParameters: const {'page': 1, 'limit': 100},
      )).thenAnswer(
    (_) async => Response<dynamic>(
      requestOptions: RequestOptions(
        path: ApiConstants.userTracksPath('user_1'),
      ),
      data: <String, dynamic>{
        'data': <String, dynamic>{'tracks': tracks},
      },
    ),
  );
}

PlaylistEntity _playlist(
  String id, {
  required String title,
  PlaylistOwner? owner,
  int tracksCount = 2,
}) {
  return PlaylistEntity(
    playlistId: id,
    title: title,
    description: '',
    visibility: PlaylistVisibility.publicPlaylist,
    secretToken: null,
    coverImageUrl: null,
    owner: owner,
    tracks: const <Track>[],
    tracksCount: tracksCount,
    likesCount: 0,
  );
}
