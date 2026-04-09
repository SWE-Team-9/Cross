import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_processing_state.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_status.dart';

void main() {
  group('TrackProcessingState', () {
    test('idle state flags and conversions', () {
      const state = TrackProcessingIdle();

      expect(state.isIdle, isTrue);
      expect(state.isInProgress, isFalse);
      expect(state.trackId, isNull);
      expect(state.asTrackStatus, isNull);
    });

    test('in-progress exposes track and processing status', () {
      const state = TrackProcessingInProgress(trackId: 't1', pollAttempt: 2);

      expect(state.isInProgress, isTrue);
      expect(state.trackId, 't1');
      expect(state.asTrackStatus, TrackStatus.PROCESSING);
    });

    test('ready exposes track and finished status', () {
      const state = TrackProcessingReady(trackId: 't2');

      expect(state.isReady, isTrue);
      expect(state.trackId, 't2');
      expect(state.asTrackStatus, TrackStatus.FINISHED);
    });

    test('failed exposes track and failed status', () {
      const state = TrackProcessingFailed(trackId: 't3', reason: 'x');

      expect(state.isFailed, isTrue);
      expect(state.trackId, 't3');
      expect(state.asTrackStatus, TrackStatus.FAILED);
    });

    test('states support value equality for overridden props', () {
      const inProgressA = TrackProcessingInProgress(
        trackId: 't1',
        pollAttempt: 3,
      );
      const inProgressB = TrackProcessingInProgress(
        trackId: 't1',
        pollAttempt: 3,
      );

      const readyA = TrackProcessingReady(trackId: 't2');
      const readyB = TrackProcessingReady(trackId: 't2');

      const failedA = TrackProcessingFailed(trackId: 't3', reason: 'boom');
      const failedB = TrackProcessingFailed(trackId: 't3', reason: 'boom');

      expect(inProgressA, inProgressB);
      expect(readyA, readyB);
      expect(failedA, failedB);
    });
  });
}
