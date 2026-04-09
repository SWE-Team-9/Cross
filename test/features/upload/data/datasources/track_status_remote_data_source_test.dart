import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/track_status_remote_data_source.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_status.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('TrackStatusRemoteDataSourceImpl', () {
    late MockDio mockDio;
    late TrackStatusRemoteDataSourceImpl dataSource;

    setUp(() {
      mockDio = MockDio();
      dataSource = TrackStatusRemoteDataSourceImpl(mockDio);
    });

    test('calls dio and maps response to dto', () async {
      when(() => mockDio.get('/api/v1/tracks/t1/status')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/tracks/t1/status'),
          data: {'trackId': 't1', 'status': 'FAILED'},
        ),
      );

      final dto = await dataSource.getTrackStatus('t1');

      expect(dto.trackId, 't1');
      expect(dto.status, TrackStatus.FAILED);
      verify(() => mockDio.get('/api/v1/tracks/t1/status')).called(1);
    });
  });
}
