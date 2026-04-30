import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/track_management_remote_data_source.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_form.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient mockDioClient;
  late TrackManagementRemoteDataSourceImpl dataSource;

  const form = TrackManagementForm(
    title: 'City Lights',
    description: 'Updated description',
    genreName: 'Electronic',
    tags: <String>['night', 'synth'],
    visibility: TrackManagementVisibility.privateTrack,
  );

  const metadataRequestBody = <String, dynamic>{
    'title': 'City Lights',
    'description': 'Updated description',
    'genre': 'Electronic',
    'tags': <String>['night', 'synth'],
  };

  Map<String, dynamic> trackJson({
    String id = 'track-1',
    String title = 'City Lights',
    String description = 'Updated description',
    int? genreId = 2,
    String? genreName = 'Electronic',
    List<String> tags = const <String>['night', 'synth'],
    String visibility = 'private',
    int? durationInSeconds = 184,
  }) {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'genre_id': genreId,
      'genre_name': genreName,
      'tags': tags,
      'visibility': visibility,
      'duration_in_seconds': durationInSeconds,
    };
  }

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = TrackManagementRemoteDataSourceImpl(mockDioClient);
  });

  group('updateTrackMetadata', () {
    test('parses payload from response.data.track', () async {
      when(() => mockDioClient.put(
            '/api/v1/tracks/track-1',
            data: metadataRequestBody,
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks/track-1'),
          data: <String, dynamic>{
            'track': trackJson(),
          },
        ),
      );

      final result = await dataSource.updateTrackMetadata(
        trackId: 'track-1',
        form: form,
      );

      expect(result.id, 'track-1');
      expect(result.title, 'City Lights');
      expect(result.genreId, 2);
      expect(result.genreName, 'Electronic');

      verify(() => mockDioClient.put(
            '/api/v1/tracks/track-1',
            data: metadataRequestBody,
          )).called(1);
    });

    test('parses payload from response.data.data', () async {
      when(() => mockDioClient.put(
            '/api/v1/tracks/track-1',
            data: metadataRequestBody,
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks/track-1'),
          data: <String, dynamic>{
            'data': trackJson(title: 'New Title'),
          },
        ),
      );

      final result = await dataSource.updateTrackMetadata(
        trackId: 'track-1',
        form: form,
      );

      expect(result.title, 'New Title');
    });

    test('parses payload from direct map response', () async {
      when(() => mockDioClient.put(
            '/api/v1/tracks/track-1',
            data: metadataRequestBody,
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks/track-1'),
          data: trackJson(title: 'Direct Map'),
        ),
      );

      final result = await dataSource.updateTrackMetadata(
        trackId: 'track-1',
        form: form,
      );

      expect(result.title, 'Direct Map');
    });

    test('throws FormatException on unexpected response shape', () async {
      when(() => mockDioClient.put(
            '/api/v1/tracks/track-1',
            data: metadataRequestBody,
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks/track-1'),
          data: 'bad-response',
        ),
      );

      expect(
        () => dataSource.updateTrackMetadata(trackId: 'track-1', form: form),
        throwsA(isA<FormatException>()),
      );
    });

    test('sends multipart coverArt when cover path is selected', () async {
      final temp = await Directory.systemTemp.createTemp('managed_cover_test');
      final coverFile = File('${temp.path}/cover.png');
      await coverFile.writeAsBytes(const [1, 2, 3]);

      final formWithCover = form.copyWith(coverArtPath: coverFile.path);

      when(() => mockDioClient.put(
            '/api/v1/tracks/track-1',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks/track-1'),
          data: trackJson(),
        ),
      );

      await dataSource.updateTrackMetadata(
        trackId: 'track-1',
        form: formWithCover,
      );

      final captured = verify(() => mockDioClient.put(
            '/api/v1/tracks/track-1',
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          )).captured.single as FormData;

      expect(captured.files.any((entry) => entry.key == 'coverArt'), isTrue);
    });
  });

  group('updateTrackVisibility', () {
    test('updateTrackVisibility sends visibility api value and parses entity',
        () async {
      when(() => mockDioClient.patch(
            '/api/v1/tracks/track-1/visibility',
            data: <String, dynamic>{'visibility': 'PUBLIC'},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions:
              RequestOptions(path: '/api/v1/tracks/track-1/visibility'),
          data: <String, dynamic>{
            'track': trackJson(visibility: 'PUBLIC'),
          },
        ),
      );

      final result = await dataSource.updateTrackVisibility(
        trackId: 'track-1',
        visibility: TrackManagementVisibility.publicTrack,
      );

      expect(result.visibility, TrackManagementVisibility.publicTrack);

      verify(() => mockDioClient.patch(
            '/api/v1/tracks/track-1/visibility',
            data: <String, dynamic>{'visibility': 'PUBLIC'},
          )).called(1);
    });
  });

  group('deleteTrack', () {
    test('delegates delete to dio client', () async {
      when(() => mockDioClient.delete('/api/v1/tracks/track-1'))
          .thenAnswer((_) async => Response<void>(
                requestOptions: RequestOptions(path: '/api/v1/tracks/track-1'),
              ));

      await dataSource.deleteTrack(trackId: 'track-1');

      verify(() => mockDioClient.delete('/api/v1/tracks/track-1')).called(1);
    });
  });
}
