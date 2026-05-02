import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/playlists/data/datasources/playlists_remote_data_source.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late PlaylistsRemoteDataSourceImpl dataSource;

  setUp(() {
    dioClient = MockDioClient();
    dataSource = PlaylistsRemoteDataSourceImpl(dioClient);
  });

  group('getMyPlaylists', () {
    test('parses playlists list from nested data.playlists', () async {
      when(() => dioClient.get(
            '/api/v1/playlists/me',
            queryParameters: {'page': 1, 'limit': 20},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/me'),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'playlists': [
                <String, dynamic>{
                  'playlistId': 'pl_1',
                  'title': 'Late Night Drive',
                  'description': 'Chill tracks',
                  'visibility': 'PUBLIC',
                  'tracksCount': 12,
                },
              ],
            },
          },
        ),
      );

      final result = await dataSource.getMyPlaylists();

      expect(result, hasLength(1));
      expect(result.first.playlistId, 'pl_1');
      expect(result.first.title, 'Late Night Drive');
      expect(result.first.visibility, PlaylistVisibility.publicPlaylist);
    });

    test('returns empty when payload has no playlist list', () async {
      when(() => dioClient.get(
            '/api/v1/playlists/me',
            queryParameters: {'page': 1, 'limit': 20},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/me'),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'playlists': <String, dynamic>{'not': 'a-list'},
            },
          },
        ),
      );

      final result = await dataSource.getMyPlaylists();
      expect(result, isEmpty);
    });

    test('parses playlists from top-level json string list', () async {
      when(() => dioClient.get(
            '/api/v1/playlists/me',
            queryParameters: {'page': 3, 'limit': 2},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/me'),
          data: '''
          {
            "items": [
              {
                "playlistId": "pl_string",
                "title": "String Payload",
                "visibility": "PUBLIC"
              }
            ]
          }
          ''',
        ),
      );

      final result = await dataSource.getMyPlaylists(page: 3, limit: 2);

      expect(result.single.playlistId, 'pl_string');
      expect(result.single.title, 'String Payload');
    });
  });

  group('getTopPlaylists', () {
    test('flattens playlists grouped by genre', () async {
      when(() => dioClient.get(
            '/api/v1/playlists/top',
            queryParameters: {'limit': 10},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/top'),
          data: <String, dynamic>{
            'genres': <dynamic>[
              <String, dynamic>{
                'genre': 'Electronic',
                'playlists': <dynamic>[
                  <String, dynamic>{
                    'playlistId': 'pl_electronic',
                    'title': 'Late Night Drive',
                    'visibility': 'PUBLIC',
                    'likesCount': 48,
                  },
                ],
              },
              <String, dynamic>{
                'genre': 'Rock',
                'playlists': <dynamic>[
                  <String, dynamic>{
                    'playlistId': 'pl_rock',
                    'title': 'Garage Mix',
                    'visibility': 'PUBLIC',
                    'likesCount': 31,
                    'genre': 'alternative',
                  },
                ],
              },
            ],
          },
        ),
      );

      final result = await dataSource.getTopPlaylists();

      expect(result, hasLength(2));
      expect(result.first.playlistId, 'pl_electronic');
      expect(result.first.genre, 'Electronic');
      expect(result.first.likesCount, 48);
      expect(result.last.playlistId, 'pl_rock');
      expect(result.last.genre, 'alternative');
      expect(result.last.likesCount, 31);
    });

    test('flattens playlists grouped by genre under data', () async {
      when(() => dioClient.get(
            '/api/v1/playlists/top',
            queryParameters: {'limit': 5},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/top'),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'genres': <dynamic>[
                <String, dynamic>{
                  'genre_name': 'Hip-Hop',
                  'items': <dynamic>[
                    <String, dynamic>{
                      'playlistId': 'pl_hiphop',
                      'title': 'Bars',
                      'visibility': 'PUBLIC',
                    },
                  ],
                },
              ],
            },
          },
        ),
      );

      final result = await dataSource.getTopPlaylists(limit: 5);

      expect(result, hasLength(1));
      expect(result.single.playlistId, 'pl_hiphop');
      expect(result.single.genre, 'Hip-Hop');
    });

    test('returns empty list when grouped top playlists are empty', () async {
      when(() => dioClient.get(
            '/api/v1/playlists/top',
            queryParameters: {'limit': 10},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/top'),
          data: <String, dynamic>{
            'genres': <dynamic>[
              <String, dynamic>{
                'genre': 'Electronic',
                'playlists': <dynamic>[],
              },
            ],
          },
        ),
      );

      final result = await dataSource.getTopPlaylists();

      expect(result, isEmpty);
    });
  });

  group('getRecentPlaylists', () {
    test('parses recent playlists from documented playlists payload', () async {
      when(() => dioClient.get(
            '/api/v1/playlists/recent',
            queryParameters: {'limit': 10},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/recent'),
          data: <String, dynamic>{
            'playlists': <dynamic>[
              <String, dynamic>{
                'playlistId': 'pl_recent',
                'title': 'Recently Played',
                'description': 'Recent playlist',
                'visibility': 'PUBLIC',
                'coverImageUrl': 'https://cdn.example/recent.jpg',
                'tracksCount': 3,
                'likesCount': 12,
                'isLiked': true,
                'owner': <String, dynamic>{
                  'id': 'owner_1',
                  'display_name': 'Ahmed Hassan',
                },
              },
            ],
          },
        ),
      );

      final result = await dataSource.getRecentPlaylists();

      expect(result, hasLength(1));
      expect(result.single.playlistId, 'pl_recent');
      expect(result.single.title, 'Recently Played');
      expect(result.single.coverImageUrl, 'https://cdn.example/recent.jpg');
      expect(result.single.tracksCount, 3);
      expect(result.single.likesCount, 12);
      expect(result.single.isLiked, isTrue);
      expect(result.single.owner?.displayName, 'Ahmed Hassan');
    });
  });

  group('getLikedPlaylists', () {
    test('parses liked playlists from paginated payload', () async {
      when(() => dioClient.get(
            '/api/v1/playlists/me/liked',
            queryParameters: {'page': 2, 'limit': 5},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/me/liked'),
          data: <String, dynamic>{
            'page': 2,
            'limit': 5,
            'total': 1,
            'playlists': <dynamic>[
              <String, dynamic>{
                'playlistId': 'pl_liked',
                'title': 'Liked Playlist',
                'visibility': 'PUBLIC',
                'tracksCount': 8,
                'likesCount': 99,
                'isLiked': true,
              },
            ],
          },
        ),
      );

      final result = await dataSource.getLikedPlaylists(page: 2, limit: 5);

      expect(result, hasLength(1));
      expect(result.single.playlistId, 'pl_liked');
      expect(result.single.tracksCount, 8);
      expect(result.single.likesCount, 99);
      expect(result.single.isLiked, isTrue);
    });
  });

  group('createPlaylist', () {
    test('sends visibility API value and parses created playlist', () async {
      when(() => dioClient.post(
            '/api/v1/playlists',
            data: {
              'title': 'Focus Mix',
              'description': 'Coding tracks',
              'visibility': 'SECRET',
              'trackIds': ['trk_1'],
            },
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists'),
          data: <String, dynamic>{
            'playlistId': 'pl_101',
            'title': 'Focus Mix',
            'description': 'Coding tracks',
            'visibility': 'SECRET',
            'secretToken': 'sec_abc',
          },
        ),
      );

      final result = await dataSource.createPlaylist(
        title: 'Focus Mix',
        description: 'Coding tracks',
        visibility: PlaylistVisibility.privatePlaylist,
        initialTrackIds: ['trk_1'],
      );

      expect(result.playlistId, 'pl_101');
      expect(result.visibility, PlaylistVisibility.privatePlaylist);
      expect(result.secretToken, 'sec_abc');
    });

    test('trims non-empty genre before sending body', () async {
      when(() => dioClient.post(
            '/api/v1/playlists',
            data: {
              'title': 'Genre Playlist',
              'description': '',
              'visibility': 'SECRET',
              'trackIds': const <String>[],
              'genre': 'Ambient',
            },
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists'),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'playlistId': 'pl_genre',
              'title': 'Genre Playlist',
              'visibility': 'SECRET',
            },
          },
        ),
      );

      final result = await dataSource.createPlaylist(
        title: 'Genre Playlist',
        description: '',
        visibility: PlaylistVisibility.privatePlaylist,
        genre: '  Ambient  ',
      );

      expect(result.playlistId, 'pl_genre');
      verify(() => dioClient.post(
            '/api/v1/playlists',
            data: {
              'title': 'Genre Playlist',
              'description': '',
              'visibility': 'SECRET',
              'trackIds': const <String>[],
              'genre': 'Ambient',
            },
          )).called(1);
    });
  });

  group('getPlaylistDetails', () {
    test('parses playlist from string payload', () async {
      when(() => dioClient.get('/api/v1/playlists/pl_7')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/pl_7'),
          data:
              '{"data":{"playlistId":"pl_7","title":"Road Trip","description":"desc","visibility":"PUBLIC"}}',
        ),
      );

      final result = await dataSource.getPlaylistDetails('pl_7');

      expect(result.playlistId, 'pl_7');
      expect(result.title, 'Road Trip');
    });

    test('parses documented playlist details with owner and tracks', () async {
      when(() => dioClient.get('/api/v1/playlists/pl_101')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/pl_101'),
          data: <String, dynamic>{
            'playlistId': 'pl_101',
            'title': 'Late Night Drive',
            'description': 'My favorite chill tracks',
            'visibility': 'PUBLIC',
            'secretToken': null,
            'genre': 'Electronic',
            'coverImageUrl': 'https://cdn.example/pl_101.jpg',
            'tracksCount': 1,
            'likesCount': 48,
            'isLiked': true,
            'owner': <String, dynamic>{
              'id': 'usr_1',
              'display_name': 'Ahmed Hassan',
            },
            'tracks': <dynamic>[
              <String, dynamic>{
                'trackId': 'trk_123',
                'title': 'Layali',
                'artist': <String, dynamic>{
                  'id': 'usr_1',
                  'display_name': 'Ahmed Hassan',
                },
                'coverArtUrl': 'https://cdn.example/trk_123.jpg',
                'durationMs': 180000,
              },
            ],
          },
        ),
      );

      final result = await dataSource.getPlaylistDetails('pl_101');

      expect(result.playlistId, 'pl_101');
      expect(result.title, 'Late Night Drive');
      expect(result.genre, 'Electronic');
      expect(result.coverImageUrl, 'https://cdn.example/pl_101.jpg');
      expect(result.tracksCount, 1);
      expect(result.likesCount, 48);
      expect(result.isLiked, isTrue);
      expect(result.owner?.displayName, 'Ahmed Hassan');
      expect(result.tracks, hasLength(1));
      expect(result.tracks.single.id, 'trk_123');
      expect(result.tracks.single.title, 'Layali');
      expect(result.tracks.single.artist, 'Ahmed Hassan');
      expect(
          result.tracks.single.artworkUrl, 'https://cdn.example/trk_123.jpg');
    });

    test(
      'parses owner-only secret token from documented details payload',
      () async {
        when(() => dioClient.get('/api/v1/playlists/pl_secret')).thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/v1/playlists/pl_secret'),
            data: <String, dynamic>{
              'data': <String, dynamic>{
                'playlistId': 'pl_secret',
                'title': 'Vibes',
                'description': 'My favorite chill tracks',
                'visibility': 'SECRET',
                'secretToken': '2e8b35f8-98d2-4f78-8899-b5fb688d809a',
                'owner': <String, dynamic>{
                  'id': 'owner_1',
                  'displayName': 'Menna',
                },
                'tracks': <dynamic>[],
              },
            },
          ),
        );

        final result = await dataSource.getPlaylistDetails('pl_secret');

        expect(result.playlistId, 'pl_secret');
        expect(result.visibility, PlaylistVisibility.privatePlaylist);
        expect(result.secretToken, '2e8b35f8-98d2-4f78-8899-b5fb688d809a');
        expect(result.owner?.id, 'owner_1');
        expect(result.owner?.displayName, 'Menna');
        expect(result.tracks, isEmpty);
      },
    );

    test('sends pagination and enriches tracks with missing artists', () async {
      when(() => dioClient.get(
            '/api/v1/playlists/pl_42',
            queryParameters: {'limit': 2, 'offset': 4},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/pl_42'),
          data: <String, dynamic>{
            'playlist': <String, dynamic>{
              'playlistId': 'pl_42',
              'title': 'Needs Details',
              'visibility': 'PUBLIC',
              'tracks': <dynamic>[
                <String, dynamic>{
                  'id': 'trk_needs_artist',
                  'title': 'Before',
                  'artist': 'Unknown artist',
                },
              ],
            },
          },
        ),
      );
      when(() => dioClient.get('/api/v1/tracks/trk_needs_artist')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: '/api/v1/tracks/trk_needs_artist'),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'title': 'After',
              'artist': <String, dynamic>{
                'displayName': 'Enriched Artist',
                'handle': 'enriched',
                'userId': 'artist_42',
              },
              'streamUrl': 'https://cdn.example/enriched.mp3',
              'artwork_url': 'https://cdn.example/enriched.jpg',
              'likes_count': 13,
              'reposts_count': 4,
              'duration_ms': 211000,
            },
          },
        ),
      );

      final result = await dataSource.getPlaylistDetails(
        'pl_42',
        limit: 2,
        offset: 4,
      );

      expect(result.tracks.single.title, 'After');
      expect(result.tracks.single.artist, 'Enriched Artist');
      expect(result.tracks.single.audioUrl, 'https://cdn.example/enriched.mp3');
      expect(
        result.tracks.single.artworkUrl,
        'https://cdn.example/enriched.jpg',
      );
      expect(result.tracks.single.handle, 'enriched');
      expect(result.tracks.single.artistId, 'artist_42');
      expect(result.tracks.single.likesCount, 13);
      expect(result.tracks.single.repostsCount, 4);
      expect(result.tracks.single.durationMs, 211000);
    });

    test('keeps original track when detail enrichment fails', () async {
      when(() => dioClient.get('/api/v1/playlists/pl_failed')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/pl_failed'),
          data: <String, dynamic>{
            'playlistId': 'pl_failed',
            'title': 'Fallback',
            'visibility': 'PUBLIC',
            'tracks': <dynamic>[
              <String, dynamic>{
                'id': 'trk_failed',
                'title': 'Original',
                'artist': 'Unkown artist',
              },
            ],
          },
        ),
      );
      when(() => dioClient.get('/api/v1/tracks/trk_failed'))
          .thenThrow(Exception('not found'));

      final result = await dataSource.getPlaylistDetails('pl_failed');

      expect(result.tracks.single.title, 'Original');
      expect(result.tracks.single.artist, 'Unkown artist');
    });

    test('getPlaylistEditDetails parses edit payload', () async {
      when(() => dioClient.get('/api/v1/playlists/pl_42/edit')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/pl_42/edit'),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'playlistId': 'pl_42',
              'title': 'Editable',
              'visibility': 'SECRET',
            },
          },
        ),
      );

      final result = await dataSource.getPlaylistEditDetails('pl_42');

      expect(result.playlistId, 'pl_42');
      expect(result.title, 'Editable');
      expect(result.visibility, PlaylistVisibility.privatePlaylist);
    });
  });

  group('update/delete and track actions', () {
    test('updatePlaylist sends patch payload only for provided fields',
        () async {
      when(() => dioClient.patch(
            '/api/v1/playlists/pl_10',
            data: {
              'title': 'Updated',
              'visibility': 'SECRET',
              'genre': 'electronic',
            },
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/pl_10'),
          data: const <String, dynamic>{},
        ),
      );

      await dataSource.updatePlaylist(
        playlistId: 'pl_10',
        title: 'Updated',
        visibility: PlaylistVisibility.privatePlaylist,
        genre: ' electronic ',
      );

      verify(() => dioClient.patch(
            '/api/v1/playlists/pl_10',
            data: {
              'title': 'Updated',
              'visibility': 'SECRET',
              'genre': 'electronic',
            },
          )).called(1);
    });

    test('updatePlaylist sends all optional fields with formatted release date',
        () async {
      when(() => dioClient.patch(
            '/api/v1/playlists/pl_12',
            data: {
              'title': 'Updated',
              'description': 'Fresh description',
              'visibility': 'PUBLIC',
              'genre': 'Jazz',
              'type': 'ALBUM',
              'releaseDate': '2026-05-02',
              'tags': ['late', 'night'],
            },
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/pl_12'),
          data: const <String, dynamic>{},
        ),
      );

      await dataSource.updatePlaylist(
        playlistId: 'pl_12',
        title: 'Updated',
        description: 'Fresh description',
        visibility: PlaylistVisibility.publicPlaylist,
        genre: '  Jazz  ',
        playlistType: 'ALBUM',
        releaseDate: DateTime.utc(2026, 5, 2, 12),
        tags: ['late', 'night'],
      );

      verify(() => dioClient.patch(
            '/api/v1/playlists/pl_12',
            data: {
              'title': 'Updated',
              'description': 'Fresh description',
              'visibility': 'PUBLIC',
              'genre': 'Jazz',
              'type': 'ALBUM',
              'releaseDate': '2026-05-02',
              'tags': ['late', 'night'],
            },
          )).called(1);
    });

    test('uploadPlaylistCover returns urls from cover payload variants',
        () async {
      final tempFile = File(
        '${Directory.systemTemp.path}/playlist-cover-test-${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(<int>[1, 2, 3]);
      addTearDown(() {
        if (tempFile.existsSync()) tempFile.deleteSync();
      });

      var responseIndex = 0;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            responseIndex++;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: responseIndex == 1
                    ? <String, dynamic>{
                        'data': <String, dynamic>{
                          'cover_image_url':
                              'https://cdn.example/nested-cover.jpg',
                        },
                      }
                    : <String, dynamic>{
                        'coverUrl': 'https://cdn.example/top-cover.jpg',
                      },
              ),
            );
          },
        ),
      );
      when(() => dioClient.dio).thenReturn(dio);

      final nestedUrl = await dataSource.uploadPlaylistCover(
        playlistId: 'pl_12',
        filePath: tempFile.path,
      );
      final topLevelUrl = await dataSource.uploadPlaylistCover(
        playlistId: 'pl_12',
        filePath: tempFile.path,
      );

      expect(nestedUrl, 'https://cdn.example/nested-cover.jpg');
      expect(topLevelUrl, 'https://cdn.example/top-cover.jpg');
    });

    test('uploadPlaylistCover returns null when response has no url', () async {
      final tempFile = File(
        '${Directory.systemTemp.path}/playlist-cover-empty-${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(<int>[1]);
      addTearDown(() {
        if (tempFile.existsSync()) tempFile.deleteSync();
      });

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: const <String, dynamic>{'data': <String, dynamic>{}},
              ),
            );
          },
        ),
      );
      when(() => dioClient.dio).thenReturn(dio);

      final result = await dataSource.uploadPlaylistCover(
        playlistId: 'pl_empty',
        filePath: tempFile.path,
      );

      expect(result, isNull);
    });

    test('deletePlaylist uses expected endpoint', () async {
      when(() => dioClient.delete('/api/v1/playlists/pl_12')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/pl_12'),
          data: const <String, dynamic>{},
        ),
      );

      await dataSource.deletePlaylist('pl_12');

      verify(() => dioClient.delete('/api/v1/playlists/pl_12')).called(1);
    });

    test('recordPlaylistPlayback hits playlist play endpoint', () async {
      when(() => dioClient.post('/api/v1/playlists/pl_12/play')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/pl_12/play'),
          data: const <String, dynamic>{},
        ),
      );

      await dataSource.recordPlaylistPlayback('pl_12');

      verify(() => dioClient.post('/api/v1/playlists/pl_12/play')).called(1);
    });

    test('addTrackToPlaylist sends track id body', () async {
      when(() => dioClient.post(
            '/api/v1/playlists/pl_3/tracks',
            data: {'trackId': 'trk_77'},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/playlists/pl_3/tracks'),
          data: const <String, dynamic>{},
        ),
      );

      await dataSource.addTrackToPlaylist(
        playlistId: 'pl_3',
        trackId: 'trk_77',
      );

      verify(() => dioClient.post(
            '/api/v1/playlists/pl_3/tracks',
            data: {'trackId': 'trk_77'},
          )).called(1);
    });

    test('removeTrackFromPlaylist hits delete track endpoint', () async {
      when(() => dioClient.delete('/api/v1/playlists/pl_3/tracks/trk_77'))
          .thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: '/api/v1/playlists/pl_3/tracks/trk_77'),
          data: const <String, dynamic>{},
        ),
      );

      await dataSource.removeTrackFromPlaylist(
        playlistId: 'pl_3',
        trackId: 'trk_77',
      );

      verify(() => dioClient.delete('/api/v1/playlists/pl_3/tracks/trk_77'))
          .called(1);
    });

    test('reorderPlaylistTracks sends ordered track ids', () async {
      when(() => dioClient.patch(
            '/api/v1/playlists/pl_3/reorder',
            data: {
              'orderedTrackIds': ['trk_2', 'trk_1'],
            },
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: '/api/v1/playlists/pl_3/reorder'),
          data: const <String, dynamic>{},
        ),
      );

      await dataSource.reorderPlaylistTracks(
        playlistId: 'pl_3',
        orderedTrackIds: ['trk_2', 'trk_1'],
      );

      verify(() => dioClient.patch(
            '/api/v1/playlists/pl_3/reorder',
            data: {
              'orderedTrackIds': ['trk_2', 'trk_1'],
            },
          )).called(1);
    });
  });

  group('searchPublicPlaylists', () {
    test('returns empty list for blank query without network call', () async {
      final result = await dataSource.searchPublicPlaylists('   ');

      expect(result, isEmpty);
      verifyNever(
        () => dioClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      );
    });

    test('parses playlists from discovery search results', () async {
      when(() => dioClient.get(
            '/api/v1/discovery/search',
            queryParameters: {
              'q': 'lofi',
              'type': 'playlists',
              'page': 2,
              'limit': 3,
            },
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/discovery/search'),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'results': <dynamic>[
                <String, dynamic>{
                  'playlistId': 'pl_search',
                  'title': 'Lofi Search',
                  'visibility': 'PUBLIC',
                },
              ],
            },
          },
        ),
      );

      final result = await dataSource.searchPublicPlaylists(
        ' lofi ',
        page: 2,
        limit: 3,
      );

      expect(result.single.playlistId, 'pl_search');
      expect(result.single.title, 'Lofi Search');
    });

    test('returns empty list when discovery payload has no playlists',
        () async {
      when(() => dioClient.get(
            '/api/v1/discovery/search',
            queryParameters: {
              'q': 'empty',
              'type': 'playlists',
              'page': 1,
              'limit': 20,
            },
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/discovery/search'),
          data: const <String, dynamic>{'results': <dynamic>[]},
        ),
      );

      final result = await dataSource.searchPublicPlaylists('empty');

      expect(result, isEmpty);
    });
  });

  group('resolveSecretPlaylist', () {
    test('parses full documented secret playlist payload', () async {
      when(() => dioClient.get('/api/v1/playlists/secret/token_99')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: '/api/v1/playlists/secret/token_99'),
          data: <String, dynamic>{
            'playlistId': 'pl_secret',
            'title': 'Private Set',
            'description': 'Shared privately',
            'visibility': 'SECRET',
            'secretToken': 'token_99',
            'coverImageUrl': 'https://cdn.example/secret.jpg',
            'likesCount': 48,
            'isLiked': false,
            'genre': 'electronic',
            'releaseDate': '2026-03-01T00:00:00.000Z',
            'tracksCount': 12,
            'owner': <String, dynamic>{
              'id': 'usr_1',
              'displayName': 'Ahmed Hassan',
            },
            'tracks': <dynamic>[
              <String, dynamic>{
                'trackId': 'trk_123',
                'title': 'Layali',
                'coverArtUrl': 'https://cdn.example/tracks/trk_123.jpg',
                'durationMs': 240000,
                'likesCount': 156,
                'repostsCount': 42,
                'artist': <String, dynamic>{
                  'id': 'usr_456',
                  'name': 'DJ Ahmed',
                  'handle': 'dj_ahmed',
                },
              },
            ],
          },
        ),
      );

      final result = await dataSource.resolveSecretPlaylist('token_99');

      expect(result.playlistId, 'pl_secret');
      expect(result.title, 'Private Set');
      expect(result.description, 'Shared privately');
      expect(result.visibility, PlaylistVisibility.privatePlaylist);
      expect(result.secretToken, 'token_99');
      expect(result.coverImageUrl, 'https://cdn.example/secret.jpg');
      expect(result.likesCount, 48);
      expect(result.isLiked, isFalse);
      expect(result.genre, 'electronic');
      expect(result.releaseDate, DateTime.parse('2026-03-01T00:00:00.000Z'));
      expect(result.tracksCount, 12);
      expect(result.owner?.id, 'usr_1');
      expect(result.owner?.displayName, 'Ahmed Hassan');
      expect(result.tracks, hasLength(1));
      expect(result.tracks.single.id, 'trk_123');
      expect(result.tracks.single.title, 'Layali');
      expect(result.tracks.single.artworkUrl,
          'https://cdn.example/tracks/trk_123.jpg');
      expect(result.tracks.single.durationMs, 240000);
      expect(result.tracks.single.likesCount, 156);
      expect(result.tracks.single.repostsCount, 42);
      expect(result.tracks.single.artist, 'DJ Ahmed');
      expect(result.tracks.single.artistId, 'usr_456');
      expect(result.tracks.single.handle, 'dj_ahmed');
    });
    test('parses full playlist details from secret endpoint', () async {
      when(() => dioClient.get('/api/v1/playlists/secret/full_token'))
          .thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: '/api/v1/playlists/secret/full_token'),
          data: <String, dynamic>{
            'message': 'Access granted via secret token',
            'playlist': <String, dynamic>{
              'playlistId': 'pl_secret_full',
              'title': 'Secret Set',
              'description': 'Shared privately',
              'visibility': 'SECRET',
              'secretToken': 'full_token',
              'coverImageUrl': 'https://cdn.example/secret.jpg',
              'tracksCount': 1,
              'owner': <String, dynamic>{
                'id': 'owner_secret',
                'displayName': 'Secret Owner',
              },
              'tracks': <dynamic>[
                <String, dynamic>{
                  'id': 'trk_secret',
                  'title': 'Hidden Track',
                  'artist': 'Secret Artist',
                },
              ],
            },
          },
        ),
      );

      final result = await dataSource.resolveSecretPlaylist('full_token');

      expect(result.playlistId, 'pl_secret_full');
      expect(result.title, 'Secret Set');
      expect(result.visibility, PlaylistVisibility.privatePlaylist);
      expect(result.secretToken, 'full_token');
      expect(result.coverImageUrl, 'https://cdn.example/secret.jpg');
      expect(result.owner?.displayName, 'Secret Owner');
      expect(result.tracks.single.id, 'trk_secret');
    });
  });

  group('getPlaylistEmbedCode', () {
    test('returns embedCode from nested data payload', () async {
      when(() => dioClient.get('/api/v1/playlists/pl_101/embed')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: '/api/v1/playlists/pl_101/embed'),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'playlistId': 'pl_101',
              'embedCode':
                  '<iframe src="https://example.com/embed/playlists/pl_101"></iframe>',
            },
          },
        ),
      );

      final result = await dataSource.getPlaylistEmbedCode('pl_101');

      expect(result, contains('<iframe'));
      expect(result, contains('pl_101'));
    });

    test('returns top-level embed_code when not nested under data', () async {
      when(() => dioClient.get('/api/v1/playlists/pl_500/embed')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: '/api/v1/playlists/pl_500/embed'),
          data: <String, dynamic>{
            'embed_code': '<iframe src="https://example.com/pl_500"></iframe>',
          },
        ),
      );

      final result = await dataSource.getPlaylistEmbedCode('pl_500');

      expect(result, contains('pl_500'));
    });

    test('sends embed customization query parameters', () async {
      when(() => dioClient.get(
            '/api/v1/playlists/pl_custom/embed',
            queryParameters: {
              'theme': 'dark',
              'autoplay': true,
              'start': 30,
              'hideArtwork': false,
              'width': 640,
              'height': 480,
            },
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: '/api/v1/playlists/pl_custom/embed'),
          data: <String, dynamic>{
            'data': <String, dynamic>{'embedCode': '<iframe></iframe>'},
          },
        ),
      );

      final result = await dataSource.getPlaylistEmbedCode(
        'pl_custom',
        theme: 'dark',
        autoplay: true,
        start: 30,
        hideArtwork: false,
        width: 640,
        height: 480,
      );

      expect(result, '<iframe></iframe>');
    });

    test('returns empty string when embed payload is invalid', () async {
      when(() => dioClient.get('/api/v1/playlists/pl_404/embed')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: '/api/v1/playlists/pl_404/embed'),
          data: const <dynamic>[],
        ),
      );

      final result = await dataSource.getPlaylistEmbedCode('pl_404');

      expect(result, isEmpty);
    });
  });
}
