import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/interactions/data/datasources/interactions_remote_data_source.dart';
import 'package:soundcloud_clone/features/interactions/data/dto/interaction_status_dto.dart';
import 'package:soundcloud_clone/features/interactions/data/repositories/interactions_repository_impl.dart';
import 'package:soundcloud_clone/features/interactions/domain/entities/interaction_status.dart';
import 'package:soundcloud_clone/features/interactions/domain/repositories/interactions_repository.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/get_track_interaction_status_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/like_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/repost_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/unlike_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/unrepost_track_usecase.dart';

class MockDioClient extends Mock implements DioClient {}

class MockInteractionsRemoteDataSource extends Mock
    implements InteractionsRemoteDataSource {}

class MockInteractionsRepository extends Mock
    implements InteractionsRepository {}

void main() {
  group('InteractionStatusDto', () {
    test('fromJson supports alt keys and string integers', () {
      final dto = InteractionStatusDto.fromJson({
        'liked': true,
        'reposted': false,
        'like_count': '7',
        'repost_count': 2,
      });

      expect(dto.isLiked, isTrue);
      expect(dto.isReposted, isFalse);
      expect(dto.likesCount, 7);
      expect(dto.repostsCount, 2);
    });

    test('toEntity maps fields exactly', () {
      const dto = InteractionStatusDto(
        isLiked: true,
        isReposted: true,
        likesCount: 4,
        repostsCount: 3,
      );

      final entity = dto.toEntity();
      expect(entity, isA<InteractionStatus>());
      expect(entity.likesCount, 4);
      expect(entity.isReposted, isTrue);
    });
  });

  group('InteractionsRemoteDataSourceImpl', () {
    late MockDioClient dioClient;
    late InteractionsRemoteDataSourceImpl dataSource;

    setUp(() {
      dioClient = MockDioClient();
      dataSource = InteractionsRemoteDataSourceImpl(dioClient);
    });

    test('like/unlike/repost/unrepost call expected endpoints', () async {
      when(() => dioClient.post(ApiConstants.likeTrackPath('t1'))).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: ''), data: {}),
      );
      when(() => dioClient.delete(ApiConstants.likeTrackPath('t1'))).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: ''), data: {}),
      );
      when(() => dioClient.post(ApiConstants.repostTrackPath('t1'))).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: ''), data: {}),
      );
      when(() => dioClient.delete(ApiConstants.repostTrackPath('t1')))
          .thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: ''), data: {}),
      );

      await dataSource.likeTrack('t1');
      await dataSource.unlikeTrack('t1');
      await dataSource.repostTrack('t1');
      await dataSource.unrepostTrack('t1');

      verify(() => dioClient.post(ApiConstants.likeTrackPath('t1'))).called(1);
      verify(() => dioClient.delete(ApiConstants.likeTrackPath('t1')))
          .called(1);
      verify(() => dioClient.post(ApiConstants.repostTrackPath('t1')))
          .called(1);
      verify(() => dioClient.delete(ApiConstants.repostTrackPath('t1')))
          .called(1);
    });

    test('getTrackInteractionStatus parses nested data payload', () async {
      when(() => dioClient.get(ApiConstants.trackInteractionStatusPath('t1')))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'data': {
              'is_liked': true,
              'is_reposted': true,
              'likes_count': 11,
              'reposts_count': 5,
            }
          },
        ),
      );

      final status = await dataSource.getTrackInteractionStatus('t1');
      expect(status.isLiked, isTrue);
      expect(status.likesCount, 11);
    });
  });

  group('InteractionsRepositoryImpl and usecases', () {
    late MockInteractionsRemoteDataSource remote;
    late InteractionsRepositoryImpl repository;
    late MockInteractionsRepository interactionsRepository;

    setUp(() {
      remote = MockInteractionsRemoteDataSource();
      repository = InteractionsRepositoryImpl(remote);
      interactionsRepository = MockInteractionsRepository();
    });

    test('repository delegates commands and maps status dto to entity',
        () async {
      when(() => remote.likeTrack('t1')).thenAnswer((_) async {});
      when(() => remote.unlikeTrack('t1')).thenAnswer((_) async {});
      when(() => remote.repostTrack('t1')).thenAnswer((_) async {});
      when(() => remote.unrepostTrack('t1')).thenAnswer((_) async {});
      when(() => remote.getTrackInteractionStatus('t1')).thenAnswer(
        (_) async => const InteractionStatusDto(
          isLiked: false,
          isReposted: true,
          likesCount: 10,
          repostsCount: 6,
        ),
      );

      await repository.likeTrack('t1');
      await repository.unlikeTrack('t1');
      await repository.repostTrack('t1');
      await repository.unrepostTrack('t1');
      final status = await repository.getTrackInteractionStatus('t1');

      expect(status.isReposted, isTrue);
      expect(status.repostsCount, 6);
    });

    test('usecases forward calls to repository', () async {
      when(() => interactionsRepository.likeTrack('track'))
          .thenAnswer((_) async {});
      when(() => interactionsRepository.unlikeTrack('track'))
          .thenAnswer((_) async {});
      when(() => interactionsRepository.repostTrack('track'))
          .thenAnswer((_) async {});
      when(() => interactionsRepository.unrepostTrack('track'))
          .thenAnswer((_) async {});
      when(() => interactionsRepository.getTrackInteractionStatus('track'))
          .thenAnswer(
        (_) async => const InteractionStatus(
          isLiked: true,
          isReposted: false,
          likesCount: 8,
          repostsCount: 1,
        ),
      );

      final like = LikeTrackUseCase(interactionsRepository);
      final unlike = UnlikeTrackUseCase(interactionsRepository);
      final repost = RepostTrackUseCase(interactionsRepository);
      final unrepost = UnrepostTrackUseCase(interactionsRepository);
      final getStatus =
          GetTrackInteractionStatusUseCase(interactionsRepository);

      await like('track');
      await unlike('track');
      await repost('track');
      await unrepost('track');
      final status = await getStatus('track');

      expect(status.isLiked, isTrue);
      verify(() => interactionsRepository.likeTrack('track')).called(1);
      verify(() => interactionsRepository.unlikeTrack('track')).called(1);
      verify(() => interactionsRepository.repostTrack('track')).called(1);
      verify(() => interactionsRepository.unrepostTrack('track')).called(1);
    });
  });
}
