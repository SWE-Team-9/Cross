import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/playback/data/datasources/track_detail_remote_data_source.dart';
import 'package:soundcloud_clone/features/playback/data/dto/track_detail_dto.dart';
import 'package:soundcloud_clone/features/playback/data/dto/track_source_dto.dart';
import 'package:soundcloud_clone/features/playback/data/repositories/track_detail_repository_impl.dart';
import 'package:soundcloud_clone/features/playback/domain/repositories/i_track_detail_repository.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_by_secret_use_case.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';

class MockDioClient extends Mock implements DioClient {}

class MockTrackDetailRemoteDataSource extends Mock
    implements TrackDetailRemoteDataSource {}

class MockTrackDetailRepository extends Mock
    implements ITrackDetailRepository {}

void main() {
  group('TrackSourceDto', () {
    test('fromJson applies defaults and isPlayable getter', () {
      final blocked = TrackSourceDto.fromJson({});
      expect(blocked.isPlayable, isFalse);

      final playable = TrackSourceDto.fromJson({
        'trackId': 't1',
        'streamUrl': 'https://cdn/t1.mp3',
        'accessState': 'PLAYABLE',
      });
      expect(playable.trackId, 't1');
      expect(playable.isPlayable, isTrue);
    });
  });

  group('TrackDetailDto and TrackDetail entity', () {
    test('fromJson + toEntity + toPlaybackTrack map correctly', () {
      final dto = TrackDetailDto.fromJson({
        'trackId': 't1',
        'title': 'Song',
        'artist': 'Ali',
        'artistId': 'a1',
        'artistHandle': 'ali',
        'coverArtUrl': 'https://img',
        'durationMs': 123000,
        'likesCount': 7,
        'repostsCount': 2,
        'waveformData': [0.1, 0.5, 0.9],
      });

      final detail = dto.toEntity(streamUrl: 'https://cdn/audio.mp3');
      final playbackTrack = detail.toPlaybackTrack();

      expect(detail.trackId, 't1');
      expect(detail.waveformData.normalizedPeaks, isNotEmpty);
      expect(playbackTrack, isA<Track>());
      expect(playbackTrack.audioUrl, 'https://cdn/audio.mp3');
      expect(playbackTrack.handle, 'ali');
      expect(playbackTrack.durationMs, 123000);
    });
  });

  group('TrackDetailRemoteDataSource', () {
    late MockDioClient client;
    late TrackDetailRemoteDataSource dataSource;

    setUp(() {
      client = MockDioClient();
      dataSource = TrackDetailRemoteDataSource(client);
    });

    test('fetch methods hit expected routes and parse payloads', () async {
      when(() => client.get<Map<String, dynamic>>('/api/v1/tracks/t1'))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'trackId': 't1',
            'title': 'Song',
            'artist': 'Ali',
            'artistId': 'a1',
            'artistHandle': 'ali'
          },
        ),
      );
      when(() => client.get<Map<String, dynamic>>('/api/v1/tracks/secret/s1'))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'trackId': 't2',
            'title': 'Private',
            'artist': 'Mona',
            'artistId': 'a2',
            'artistHandle': 'mona'
          },
        ),
      );
      when(() => client.get<Map<String, dynamic>>(
          '/api/v1/player/tracks/t1/source')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'trackId': 't1',
            'streamUrl': 'https://cdn/t1.mp3',
            'accessState': 'PLAYABLE'
          },
        ),
      );

      final byId = await dataSource.fetchByTrackId('t1');
      final bySecret = await dataSource.fetchBySecretToken('s1');
      final source = await dataSource.fetchStreamSource('t1');

      expect(byId.trackId, 't1');
      expect(bySecret.trackId, 't2');
      expect(source.isPlayable, isTrue);
    });
  });

  group('TrackDetailRepositoryImpl and usecases', () {
    late MockTrackDetailRemoteDataSource remote;
    late TrackDetailRepositoryImpl repository;
    late MockTrackDetailRepository mockRepository;

    setUp(() {
      remote = MockTrackDetailRemoteDataSource();
      repository = TrackDetailRepositoryImpl(remote);
      mockRepository = MockTrackDetailRepository();
    });

    test('getByTrackId success returns detail', () async {
      when(() => remote.fetchByTrackId('t1')).thenAnswer(
        (_) async => TrackDetailDto.fromJson({
          'trackId': 't1',
          'title': 'Song',
          'artist': 'Ali',
          'artistId': 'a1',
          'artistHandle': 'ali',
        }),
      );
      when(() => remote.fetchStreamSource('t1')).thenAnswer(
        (_) async => const TrackSourceDto(
          trackId: 't1',
          streamUrl: 'https://cdn/t1.mp3',
          accessState: 'PLAYABLE',
        ),
      );

      final result = await repository.getByTrackId('t1');
      expect(result.failure, isNull);
      expect(result.detail?.trackId, 't1');
    });

    test('getByTrackId maps empty or blocked and catches failures', () async {
      when(() => remote.fetchByTrackId('missing')).thenAnswer(
        (_) async => TrackDetailDto.fromJson({}),
      );
      final missing = await repository.getByTrackId('missing');
      expect(missing.failure, isA<NotFoundFailure>());

      when(() => remote.fetchByTrackId('t2')).thenAnswer(
        (_) async => TrackDetailDto.fromJson({
          'trackId': 't2',
          'title': 'Song',
          'artist': 'Ali',
          'artistId': 'a1',
          'artistHandle': 'ali',
        }),
      );
      when(() => remote.fetchStreamSource('t2')).thenAnswer(
        (_) async => const TrackSourceDto(
          trackId: 't2',
          streamUrl: 'https://cdn/t2.mp3',
          accessState: 'BLOCKED',
        ),
      );
      final blocked = await repository.getByTrackId('t2');
      expect(blocked.failure, isA<ForbiddenFailure>());

      when(() => remote.fetchByTrackId('network'))
          .thenThrow(NetworkFailure('offline'));
      final network = await repository.getByTrackId('network');
      expect(network.failure, isA<NetworkFailure>());

      when(() => remote.fetchByTrackId('unknown')).thenThrow(Exception('x'));
      final unknown = await repository.getByTrackId('unknown');
      expect(unknown.failure, isA<ServerFailure>());
    });

    test('getBySecretToken mirrors trackId behavior', () async {
      when(() => remote.fetchBySecretToken('s1')).thenAnswer(
        (_) async => TrackDetailDto.fromJson({
          'trackId': 't9',
          'title': 'Secret',
          'artist': 'Zed',
          'artistId': 'a9',
          'artistHandle': 'zed',
        }),
      );
      when(() => remote.fetchStreamSource('t9')).thenAnswer(
        (_) async => const TrackSourceDto(
          trackId: 't9',
          streamUrl: 'https://cdn/t9.mp3',
          accessState: 'PLAYABLE',
        ),
      );

      final ok = await repository.getBySecretToken('s1');
      expect(ok.detail?.trackId, 't9');

      when(() => remote.fetchBySecretToken('bad')).thenAnswer(
        (_) async => TrackDetailDto.fromJson({}),
      );
      final missing = await repository.getBySecretToken('bad');
      expect(missing.failure, isA<NotFoundFailure>());
    });

    test('usecases call repository methods', () async {
      when(() => mockRepository.getByTrackId('t1')).thenAnswer(
        (_) async => (detail: null, failure: const NotFoundFailure('none')),
      );
      when(() => mockRepository.getBySecretToken('s1')).thenAnswer(
        (_) async =>
            (detail: null, failure: const ForbiddenFailure('forbidden')),
      );

      final byTrack = GetTrackDetailUseCase(mockRepository);
      final bySecret = GetTrackBySecretUseCase(mockRepository);

      final trackResult = await byTrack('t1');
      final secretResult = await bySecret('s1');

      expect(trackResult.failure, isA<NotFoundFailure>());
      expect(secretResult.failure, isA<ForbiddenFailure>());
      verify(() => mockRepository.getByTrackId('t1')).called(1);
      verify(() => mockRepository.getBySecretToken('s1')).called(1);
    });
  });
}
