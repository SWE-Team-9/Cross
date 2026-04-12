import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/track_status_remote_data_source.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_status.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  group('TrackStatusRemoteDataSourceImpl', () {
    late MockDioClient mockDioClient;
    late TrackStatusRemoteDataSourceImpl dataSource;

    setUp(() {
      mockDioClient = MockDioClient();
      dataSource = TrackStatusRemoteDataSourceImpl(mockDioClient);
    });

    test('calls dio client and maps response to dto', () async {
      when(() => mockDioClient.get(ApiConstants.trackStatusPath('t1')))
          .thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(
            path: ApiConstants.trackStatusPath('t1'),
          ),
          data: {'trackId': 't1', 'status': 'FAILED'},
        ),
      );

      final dto = await dataSource.getTrackStatus('t1');

      expect(dto.trackId, 't1');
      expect(dto.status, TrackStatus.FAILED);
      verify(() => mockDioClient.get(ApiConstants.trackStatusPath('t1')))
          .called(1);
    });
  });
}
