import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_processing_status.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_status.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/i_track_status_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/watch_track_processing_status_use_case.dart';

class MockTrackStatusRepository extends Mock
    implements ITrackStatusRepository {}

void main() {
  group('WatchTrackProcessingStatusUseCase', () {
    late MockTrackStatusRepository mockRepository;
    late WatchTrackProcessingStatusUseCase useCase;

    setUp(() {
      mockRepository = MockTrackStatusRepository();
      useCase = WatchTrackProcessingStatusUseCase(mockRepository);
    });

    test('emits terminal status and closes stream', () async {
      when(() => mockRepository.getTrackStatus('t1')).thenAnswer(
        (_) async => (
          status: const TrackProcessingStatus(
            trackId: 't1',
            status: TrackStatus.FINISHED,
          ),
          failure: null,
        ),
      );

      final result = await useCase('t1').toList();

      expect(result, hasLength(1));
      expect(result.first.status, TrackStatus.FINISHED);
      verify(() => mockRepository.getTrackStatus('t1')).called(1);
    });

    test('maps repository failure to FAILED status', () async {
      when(() => mockRepository.getTrackStatus('t1')).thenAnswer(
        (_) async => (
          status: null,
          failure: const ServerFailure('boom'),
        ),
      );

      final result = await useCase('t1').toList();

      expect(result, hasLength(1));
      expect(result.first.trackId, 't1');
      expect(result.first.status, TrackStatus.FAILED);
    });

    test('continues polling when status is processing then stops on terminal',
        () async {
      var calls = 0;
      when(() => mockRepository.getTrackStatus('t1')).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          return (
            status: const TrackProcessingStatus(
              trackId: 't1',
              status: TrackStatus.PROCESSING,
            ),
            failure: null,
          );
        }

        return (
          status: const TrackProcessingStatus(
            trackId: 't1',
            status: TrackStatus.FINISHED,
          ),
          failure: null,
        );
      });

      final emitted = <TrackProcessingStatus>[];
      await for (final item in useCase('t1')) {
        emitted.add(item);
        if (item.isTerminal) {
          break;
        }
      }

      expect(emitted, hasLength(2));
      expect(emitted.first.status, TrackStatus.PROCESSING);
      expect(emitted.last.status, TrackStatus.FINISHED);
      expect(calls, 2);
    });
  });
}
