import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/interactions/domain/entities/interaction_status.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/get_track_interaction_status_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/like_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/repost_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/unlike_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/unrepost_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';

class MockGetTrackInteractionStatusUseCase extends Mock
    implements GetTrackInteractionStatusUseCase {}

class MockLikeTrackUseCase extends Mock implements LikeTrackUseCase {}

class MockUnlikeTrackUseCase extends Mock implements UnlikeTrackUseCase {}

class MockRepostTrackUseCase extends Mock implements RepostTrackUseCase {}

class MockUnrepostTrackUseCase extends Mock implements UnrepostTrackUseCase {}

void main() {
  late MockGetTrackInteractionStatusUseCase getStatus;
  late MockLikeTrackUseCase like;
  late MockUnlikeTrackUseCase unlike;
  late MockRepostTrackUseCase repost;
  late MockUnrepostTrackUseCase unrepost;

  setUp(() {
    getStatus = MockGetTrackInteractionStatusUseCase();
    like = MockLikeTrackUseCase();
    unlike = MockUnlikeTrackUseCase();
    repost = MockRepostTrackUseCase();
    unrepost = MockUnrepostTrackUseCase();
  });

  TrackInteractionCubit buildCubit() => TrackInteractionCubit(
        getTrackInteractionStatusUseCase: getStatus,
        likeTrackUseCase: like,
        unlikeTrackUseCase: unlike,
        repostTrackUseCase: repost,
        unrepostTrackUseCase: unrepost,
      );

  group('TrackInteractionCubit', () {
    test('initial state values are default', () {
      final state = buildCubit().state;
      expect(state.isLoading, isFalse);
      expect(state.isLiked, isFalse);
      expect(state.likesCount, 0);
      expect(state.isSubmittingLike, isFalse);
      expect(state.errorMessage, isNull);
    });

    blocTest<TrackInteractionCubit, TrackInteractionState>(
      'load emits loaded interaction status',
      build: () {
        when(() => getStatus('t1')).thenAnswer(
          (_) async => const InteractionStatus(
            isLiked: true,
            isReposted: true,
          ),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.load(
        trackId: 't1',
        likesCount: 9,
        repostsCount: 4,
      ),
      expect: () => [
        isA<TrackInteractionState>()
            .having((s) => s.isLoading, 'isLoading', isTrue),
        isA<TrackInteractionState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.isLiked, 'isLiked', isTrue)
            .having((s) => s.isReposted, 'isReposted', isTrue)
            .having((s) => s.likesCount, 'likesCount', 9)
            .having((s) => s.repostsCount, 'repostsCount', 4),
      ],
    );

    blocTest<TrackInteractionCubit, TrackInteractionState>(
      'toggleLike optimistic success for like then settle',
      build: () {
        when(() => like('t1')).thenAnswer((_) async {});
        return buildCubit();
      },
      seed: () => TrackInteractionState.initial().copyWith(likesCount: 3),
      act: (cubit) => cubit.toggleLike('t1'),
      expect: () => [
        isA<TrackInteractionState>()
            .having((s) => s.isSubmittingLike, 'isSubmittingLike', isTrue)
            .having((s) => s.isLiked, 'isLiked', isTrue)
            .having((s) => s.likesCount, 'likesCount', 4),
        isA<TrackInteractionState>()
            .having((s) => s.isSubmittingLike, 'isSubmittingLike', isFalse),
      ],
    );

    blocTest<TrackInteractionCubit, TrackInteractionState>(
      'toggleLike rollback on unlike failure',
      build: () {
        when(() => unlike('t1')).thenThrow(Exception('fail unlike'));
        return buildCubit();
      },
      seed: () => TrackInteractionState.initial().copyWith(
        isLiked: true,
        likesCount: 10,
      ),
      act: (cubit) => cubit.toggleLike('t1'),
      expect: () => [
        isA<TrackInteractionState>()
            .having((s) => s.isLiked, 'isLiked', isFalse)
            .having((s) => s.likesCount, 'likesCount', 9),
        isA<TrackInteractionState>()
            .having((s) => s.isLiked, 'isLiked', isTrue)
            .having((s) => s.likesCount, 'likesCount', 10)
            .having(
                (s) => s.errorMessage, 'errorMessage', contains('fail unlike')),
      ],
    );

    blocTest<TrackInteractionCubit, TrackInteractionState>(
      'toggleRepost optimistic success for repost then settle',
      build: () {
        when(() => repost('t1')).thenAnswer((_) async {});
        return buildCubit();
      },
      seed: () => TrackInteractionState.initial().copyWith(repostsCount: 1),
      act: (cubit) => cubit.toggleRepost('t1'),
      expect: () => [
        isA<TrackInteractionState>()
            .having((s) => s.isSubmittingRepost, 'isSubmittingRepost', isTrue)
            .having((s) => s.isReposted, 'isReposted', isTrue)
            .having((s) => s.repostsCount, 'repostsCount', 2),
        isA<TrackInteractionState>()
            .having((s) => s.isSubmittingRepost, 'isSubmittingRepost', isFalse),
      ],
    );

    blocTest<TrackInteractionCubit, TrackInteractionState>(
      'toggleRepost rollback on unrepost failure',
      build: () {
        when(() => unrepost('t1')).thenThrow(Exception('fail unrepost'));
        return buildCubit();
      },
      seed: () => TrackInteractionState.initial().copyWith(
        isReposted: true,
        repostsCount: 5,
      ),
      act: (cubit) => cubit.toggleRepost('t1'),
      expect: () => [
        isA<TrackInteractionState>()
            .having((s) => s.isReposted, 'isReposted', isFalse)
            .having((s) => s.repostsCount, 'repostsCount', 4),
        isA<TrackInteractionState>()
            .having((s) => s.isReposted, 'isReposted', isTrue)
            .having((s) => s.repostsCount, 'repostsCount', 5)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('fail unrepost')),
      ],
    );

    test('copyWith preserves old values and clearError resets error', () {
      const state = TrackInteractionState(
        isLoading: false,
        isSubmittingLike: false,
        isSubmittingRepost: false,
        isLiked: true,
        isReposted: false,
        likesCount: 3,
        repostsCount: 2,
        errorMessage: 'x',
      );

      final copied = state.copyWith(repostsCount: 8, clearError: true);
      expect(copied.isLiked, isTrue);
      expect(copied.repostsCount, 8);
      expect(copied.errorMessage, isNull);
    });
  });
}
