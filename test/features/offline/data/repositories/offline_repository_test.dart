import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dio;
  late OfflineRepository repository;
  late Directory tempDirectory;

  setUp(() {
    dio = MockDioClient();
    repository = OfflineRepository(dio);

    tempDirectory = Directory.systemTemp.createTempSync(
      'offline_repository_test_',
    );

    PathProviderPlatform.instance = _FakePathProviderPlatform(
      applicationDocumentsPath: tempDirectory.path,
    );

    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Response<dynamic> response(dynamic data) {
    return Response<dynamic>(
      data: data,
      requestOptions: RequestOptions(path: '/test'),
      statusCode: 200,
    );
  }

  Map<String, dynamic> entitlementJson({
    String trackId = 'track-1',
    String planCode = 'PRO',
  }) {
    return <String, dynamic>{
      'trackId': trackId,
      'title': 'Midnight Drive',
      'artist': 'DJ Nova',
      'handle': 'djnova',
      'durationMs': 214000,
      'coverArtUrl': 'https://example.com/cover.jpg',
      'downloadUrl': 'https://example.com/audio.mp3',
      'expiresAt': '2026-04-28T14:00:00.000Z',
      'expiresInSeconds': 900,
      'offlineTokenId': 'offline_mock_abc123',
      'planCode': planCode,
    };
  }

  Map<String, dynamic> trackJson({
    String trackId = 'track-1',
    String? localPath,
  }) {
    return <String, dynamic>{
      'id': trackId,
      'title': 'Midnight Drive',
      'artist': 'DJ Nova',
      'audioUrl': 'https://example.com/stream.mp3',
      'artworkUrl': 'https://example.com/cover.jpg',
      'handle': 'djnova',
      'artistId': 'artist-1',
      'likesCount': 12,
      'repostsCount': 4,
      'durationMs': 214000,
      if (localPath != null) 'localPath': localPath,
    };
  }

  group('downloadTrack', () {
    test('checks premium entitlement, downloads stream, writes file, and persists metadata', () async {
      when(
        () => dio.get(ApiConstants.subscriptionOfflineTrackPath('track-1')),
      ).thenAnswer((_) async => response(entitlementJson()));

      when(
        () => dio.get(
          ApiConstants.subscriptionOfflineTrackStreamPath('track-1'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response(<int>[1, 2, 3, 4]));

      when(
        () => dio.get(ApiConstants.trackByIdPath('track-1')),
      ).thenAnswer((_) async => response(trackJson()));

      final path = await repository.downloadTrack('track-1');

      final file = File(path);
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), <int>[1, 2, 3, 4]);
      expect(path, contains('/offline/tracks/track-1.mp3'));

      final downloadedTracks = await repository.getDownloadedTracks();
      expect(downloadedTracks, <String, String>{'track-1': path});

      final downloadedTrackDetails =
          await repository.getDownloadedTrackDetails();
      expect(downloadedTrackDetails['track-1'], isNotNull);
      expect(downloadedTrackDetails['track-1']!.id, 'track-1');
      expect(downloadedTrackDetails['track-1']!.title, 'Midnight Drive');
      expect(downloadedTrackDetails['track-1']!.artist, 'DJ Nova');
      expect(downloadedTrackDetails['track-1']!.localPath, path);

      verify(
        () => dio.get(ApiConstants.subscriptionOfflineTrackPath('track-1')),
      ).called(1);

      verify(
        () => dio.get(
          ApiConstants.subscriptionOfflineTrackStreamPath('track-1'),
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (options) => options.responseType,
              'responseType',
              ResponseType.bytes,
            ),
          ),
        ),
      ).called(1);

      verify(
        () => dio.get(ApiConstants.trackByIdPath('track-1')),
      ).called(1);
    });

    test('supports wrapped entitlement and track detail payloads', () async {
      when(
        () => dio.get(ApiConstants.subscriptionOfflineTrackPath('track-1')),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'data': entitlementJson(),
          },
        ),
      );

      when(
        () => dio.get(
          ApiConstants.subscriptionOfflineTrackStreamPath('track-1'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response(<int>[7, 8, 9]));

      when(
        () => dio.get(ApiConstants.trackByIdPath('track-1')),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'track': trackJson(),
          },
        ),
      );

      final path = await repository.downloadTrack('track-1');
      final details = await repository.getDownloadedTrackDetails();

      expect(File(path).readAsBytesSync(), <int>[7, 8, 9]);
      expect(details['track-1']!.title, 'Midnight Drive');
      expect(details['track-1']!.localPath, path);
    });

    test('supports string JSON entitlement response', () async {
      when(
        () => dio.get(ApiConstants.subscriptionOfflineTrackPath('track-1')),
      ).thenAnswer(
        (_) async => response(
          jsonEncode(entitlementJson()),
        ),
      );

      when(
        () => dio.get(
          ApiConstants.subscriptionOfflineTrackStreamPath('track-1'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response(<int>[10, 11]));

      when(
        () => dio.get(ApiConstants.trackByIdPath('track-1')),
      ).thenAnswer((_) async => response(trackJson()));

      final path = await repository.downloadTrack('track-1');

      expect(File(path).readAsBytesSync(), <int>[10, 11]);
    });

    test('uses entitlement metadata when track details cannot be fetched', () async {
      when(
        () => dio.get(ApiConstants.subscriptionOfflineTrackPath('track-1')),
      ).thenAnswer((_) async => response(entitlementJson()));

      when(
        () => dio.get(
          ApiConstants.subscriptionOfflineTrackStreamPath('track-1'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response(<int>[1, 2, 3]));

      when(
        () => dio.get(ApiConstants.trackByIdPath('track-1')),
      ).thenThrow(Exception('Track details failed'));

      final path = await repository.downloadTrack('track-1');
      final details = await repository.getDownloadedTrackDetails();

      expect(details['track-1']!.id, 'track-1');
      expect(details['track-1']!.title, 'Midnight Drive');
      expect(details['track-1']!.artist, 'DJ Nova');
      expect(details['track-1']!.artworkUrl, 'https://example.com/cover.jpg');
      expect(details['track-1']!.localPath, path);
    });

    test('trims track id and sanitizes the offline file name', () async {
      const rawTrackId = '  track/with spaces  ';
      const normalizedTrackId = 'track/with spaces';

      when(
        () => dio.get(
          ApiConstants.subscriptionOfflineTrackPath(normalizedTrackId),
        ),
      ).thenAnswer(
        (_) async => response(
          entitlementJson(trackId: normalizedTrackId),
        ),
      );

      when(
        () => dio.get(
          ApiConstants.subscriptionOfflineTrackStreamPath(normalizedTrackId),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response(<int>[1, 2, 3]));

      when(
        () => dio.get(ApiConstants.trackByIdPath(normalizedTrackId)),
      ).thenAnswer(
        (_) async => response(
          trackJson(trackId: normalizedTrackId),
        ),
      );

      final path = await repository.downloadTrack(rawTrackId);

      expect(path, contains('track_with_spaces.mp3'));

      final downloadedTracks = await repository.getDownloadedTracks();
      expect(downloadedTracks[normalizedTrackId], path);
    });

    test('throws ArgumentError when track id is empty', () async {
      expect(
        () => repository.downloadTrack('   '),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(() => dio.get(any()));
    });

    test('throws StateError and does not stream when entitlement is free plan', () async {
      when(
        () => dio.get(ApiConstants.subscriptionOfflineTrackPath('track-1')),
      ).thenAnswer(
        (_) async => response(
          entitlementJson(planCode: 'FREE'),
        ),
      );

      expect(
        () => repository.downloadTrack('track-1'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Offline downloads require a premium subscription.',
          ),
        ),
      );

      verify(
        () => dio.get(ApiConstants.subscriptionOfflineTrackPath('track-1')),
      ).called(1);

      verifyNever(
        () => dio.get(
          ApiConstants.subscriptionOfflineTrackStreamPath('track-1'),
          options: any(named: 'options'),
        ),
      );
    });

    test('throws StateError when downloaded stream is empty', () async {
      when(
        () => dio.get(ApiConstants.subscriptionOfflineTrackPath('track-1')),
      ).thenAnswer((_) async => response(entitlementJson()));

      when(
        () => dio.get(
          ApiConstants.subscriptionOfflineTrackStreamPath('track-1'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response(<int>[]));

      expect(
        () => repository.downloadTrack('track-1'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Downloaded audio file is empty.',
          ),
        ),
      );
    });

    test('converts string response body to bytes when needed', () async {
      when(
        () => dio.get(ApiConstants.subscriptionOfflineTrackPath('track-1')),
      ).thenAnswer((_) async => response(entitlementJson()));

      when(
        () => dio.get(
          ApiConstants.subscriptionOfflineTrackStreamPath('track-1'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response('audio-bytes'));

      when(
        () => dio.get(ApiConstants.trackByIdPath('track-1')),
      ).thenAnswer((_) async => response(trackJson()));

      final path = await repository.downloadTrack('track-1');

      expect(File(path).readAsStringSync(), 'audio-bytes');
    });
  });

  group('fetchTrackDetails', () {
    test('returns parsed track details from direct response', () async {
      when(
        () => dio.get(ApiConstants.trackByIdPath('track-1')),
      ).thenAnswer((_) async => response(trackJson()));

      final track = await repository.fetchTrackDetails('track-1');

      expect(track, isNotNull);
      expect(track!.id, 'track-1');
      expect(track.title, 'Midnight Drive');
      expect(track.artist, 'DJ Nova');
      expect(track.artworkUrl, 'https://example.com/cover.jpg');
      expect(track.handle, 'djnova');
      expect(track.artistId, 'artist-1');
      expect(track.likesCount, 12);
      expect(track.repostsCount, 4);
      expect(track.durationMs, 214000);
    });

    test('returns parsed track details from data wrapper', () async {
      when(
        () => dio.get(ApiConstants.trackByIdPath('track-1')),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'data': trackJson(),
          },
        ),
      );

      final track = await repository.fetchTrackDetails('track-1');

      expect(track, isNotNull);
      expect(track!.id, 'track-1');
    });

    test('returns null when API response is empty', () async {
      when(
        () => dio.get(ApiConstants.trackByIdPath('track-1')),
      ).thenAnswer((_) async => response(<String, dynamic>{}));

      final track = await repository.fetchTrackDetails('track-1');

      expect(track, isNull);
    });

    test('returns null when API throws', () async {
      when(
        () => dio.get(ApiConstants.trackByIdPath('track-1')),
      ).thenThrow(Exception('Network error'));

      final track = await repository.fetchTrackDetails('track-1');

      expect(track, isNull);
    });
  });

  group('downloaded tracks persistence', () {
    test('saveDownloadedTracks and getDownloadedTracks round trip values', () async {
      await repository.saveDownloadedTracks(
        const <String, String>{
          'track-1': '/offline/track-1.mp3',
          'track-2': '/offline/track-2.mp3',
        },
      );

      final downloadedTracks = await repository.getDownloadedTracks();

      expect(
        downloadedTracks,
        <String, String>{
          'track-1': '/offline/track-1.mp3',
          'track-2': '/offline/track-2.mp3',
        },
      );
    });

    test('getDownloadedTracks returns empty map for missing or corrupted json', () async {
      expect(await repository.getDownloadedTracks(), isEmpty);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_tracks', '{bad json');

      expect(await repository.getDownloadedTracks(), isEmpty);
    });

    test('saveDownloadedTrackDetails and getDownloadedTrackDetails round trip values', () async {
      await repository.saveDownloadedTrackDetails(
        const <String, Track>{
          'track-1': Track(
            id: 'track-1',
            title: 'Midnight Drive',
            artist: 'DJ Nova',
            audioUrl: 'https://example.com/audio.mp3',
            artworkUrl: 'https://example.com/cover.jpg',
            handle: 'djnova',
            artistId: 'artist-1',
            likesCount: 12,
            repostsCount: 4,
            durationMs: 214000,
            localPath: '/offline/track-1.mp3',
          ),
        },
      );

      final details = await repository.getDownloadedTrackDetails();
      final track = details['track-1']!;

      expect(track.id, 'track-1');
      expect(track.title, 'Midnight Drive');
      expect(track.artist, 'DJ Nova');
      expect(track.audioUrl, 'https://example.com/audio.mp3');
      expect(track.artworkUrl, 'https://example.com/cover.jpg');
      expect(track.handle, 'djnova');
      expect(track.artistId, 'artist-1');
      expect(track.likesCount, 12);
      expect(track.repostsCount, 4);
      expect(track.durationMs, 214000);
      expect(track.localPath, '/offline/track-1.mp3');
    });

    test('getDownloadedTrackDetails returns empty map for corrupted json', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_track_details', '{bad json');

      expect(await repository.getDownloadedTrackDetails(), isEmpty);
    });
  });

  group('downloaded playlists persistence', () {
    test('saveDownloadedPlaylists and getDownloadedPlaylists round trip values', () async {
      final playlist = PlaylistEntity(
        playlistId: 'playlist-1',
        title: 'Offline Mix',
        description: 'Saved playlist',
        visibility: PlaylistVisibility.public,
        genre: 'Electronic',
        genreId: 7,
        slug: 'offline-mix',
        playlistType: 'PLAYLIST',
        releaseDate: DateTime.parse('2026-04-01T00:00:00.000Z'),
        tags: const <String>['electronic', 'mix'],
        secretToken: 'secret-token',
        coverImageUrl: 'https://example.com/playlist.jpg',
        owner: const PlaylistOwner(
          id: 'owner-1',
          displayName: 'DJ Nova',
        ),
        tracks: const <Track>[
          Track(
            id: 'track-1',
            title: 'Midnight Drive',
            artist: 'DJ Nova',
            audioUrl: 'https://example.com/audio.mp3',
          ),
        ],
        tracksCount: 1,
        likesCount: 10,
        isLiked: true,
      );

      await repository.saveDownloadedPlaylists(
        <String, PlaylistEntity>{
          'playlist-1': playlist,
        },
      );

      final playlists = await repository.getDownloadedPlaylists();
      final savedPlaylist = playlists['playlist-1']!;

      expect(savedPlaylist.playlistId, 'playlist-1');
      expect(savedPlaylist.title, 'Offline Mix');
      expect(savedPlaylist.description, 'Saved playlist');
      expect(savedPlaylist.visibility, PlaylistVisibility.public);
      expect(savedPlaylist.genre, 'Electronic');
      expect(savedPlaylist.genreId, 7);
      expect(savedPlaylist.slug, 'offline-mix');
      expect(savedPlaylist.playlistType, 'PLAYLIST');
      expect(savedPlaylist.releaseDate, DateTime.parse('2026-04-01T00:00:00.000Z'));
      expect(savedPlaylist.tags, <String>['electronic', 'mix']);
      expect(savedPlaylist.secretToken, 'secret-token');
      expect(savedPlaylist.coverImageUrl, 'https://example.com/playlist.jpg');
      expect(savedPlaylist.owner!.id, 'owner-1');
      expect(savedPlaylist.owner!.displayName, 'DJ Nova');
      expect(savedPlaylist.tracks, hasLength(1));
      expect(savedPlaylist.tracks.first.id, 'track-1');
      expect(savedPlaylist.tracksCount, 1);
      expect(savedPlaylist.likesCount, 10);
      expect(savedPlaylist.isLiked, isTrue);
    });

    test('getDownloadedPlaylists returns empty map for missing or corrupted json', () async {
      expect(await repository.getDownloadedPlaylists(), isEmpty);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_playlists', '{bad json');

      expect(await repository.getDownloadedPlaylists(), isEmpty);
    });
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform({
    required this.applicationDocumentsPath,
  });

  final String applicationDocumentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return applicationDocumentsPath;
  }
}