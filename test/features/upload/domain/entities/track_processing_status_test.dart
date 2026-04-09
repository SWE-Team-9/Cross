import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_processing_status.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_status.dart';

void main() {
  group('TrackProcessingStatus', () {
    test('exposes convenience getters from status', () {
      const ready = TrackProcessingStatus(
        trackId: 't1',
        status: TrackStatus.FINISHED,
      );

      expect(ready.isTerminal, isTrue);
      expect(ready.isReady, isTrue);
      expect(ready.isProcessing, isFalse);
    });

    test('supports value equality', () {
      const a = TrackProcessingStatus(
        trackId: 't1',
        status: TrackStatus.PROCESSING,
      );
      const b = TrackProcessingStatus(
        trackId: 't1',
        status: TrackStatus.PROCESSING,
      );

      expect(a, b);
    });
  });
}
