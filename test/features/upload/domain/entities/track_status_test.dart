import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_status.dart';

void main() {
  group('TrackStatus', () {
    test('fromString maps known values case-insensitively', () {
      expect(TrackStatus.fromString('processing'), TrackStatus.PROCESSING);
      expect(TrackStatus.fromString('FINISHED'), TrackStatus.FINISHED);
      expect(TrackStatus.fromString('failed'), TrackStatus.FAILED);
    });

    test('fromString defaults to PROCESSING for unknown/null', () {
      expect(TrackStatus.fromString('weird'), TrackStatus.PROCESSING);
      expect(TrackStatus.fromString(null), TrackStatus.PROCESSING);
    });

    test('terminal and convenience flags are correct', () {
      expect(TrackStatus.PROCESSING.isTerminal, isFalse);
      expect(TrackStatus.PROCESSING.isProcessing, isTrue);

      expect(TrackStatus.FINISHED.isTerminal, isTrue);
      expect(TrackStatus.FINISHED.isReady, isTrue);

      expect(TrackStatus.FAILED.isTerminal, isTrue);
      expect(TrackStatus.FAILED.isReady, isFalse);
    });
  });
}
