import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/track_status_remote_data_source.dart';
import 'package:soundcloud_clone/features/upload/data/dto/track_status_dto.dart';
import 'package:soundcloud_clone/features/upload/data/repositories/track_status_repository_impl.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_status.dart';

class MockTrackStatusRemoteDataSource extends Mock
    implements TrackStatusRemoteDataSource {}

void main() {
  group('TrackStatusRepositoryImpl', () {
    late MockTrackStatusRemoteDataSource mockRemote;
    late TrackStatusRepositoryImpl repository;

    setUp(() {
      mockRemote = MockTrackStatusRemoteDataSource();
      repository = TrackStatusRepositoryImpl(mockRemote);
    });

    test('returns status entity on success', () async {
      when(() => mockRemote.getTrackStatus('t1')).thenAnswer(
        (_) async => const TrackStatusDto(
          trackId: 't1',
          status: TrackStatus.FINISHED,
        ),
      );

      final result = await repository.getTrackStatus('t1');

      expect(result.failure, isNull);
      expect(result.status?.trackId, 't1');
      expect(result.status?.status, TrackStatus.FINISHED);
    });

    test('maps DioException to ServerFailure', () async {
      when(() => mockRemote.getTrackStatus('t1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/tracks/t1/status'),
          message: 'network down',
        ),
      );

      final result = await repository.getTrackStatus('t1');

      expect(result.status, isNull);
      expect(result.failure, isA<ServerFailure>());
      expect(result.failure?.message, contains('network down'));
    });

    test('maps generic exception to ServerFailure', () async {
      when(() => mockRemote.getTrackStatus('t1'))
          .thenThrow(Exception('unexpected'));

      final result = await repository.getTrackStatus('t1');

      expect(result.status, isNull);
      expect(result.failure, isA<ServerFailure>());
      expect(result.failure?.message, contains('unexpected'));
    });
  });
}
