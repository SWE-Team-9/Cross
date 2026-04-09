import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/waveform_data.dart';

void main() {
  group('WaveformData', () {
    test('empty factory returns empty waveform', () {
      const data = WaveformData.empty();

      expect(data.isEmpty, isTrue);
      expect(data.isNotEmpty, isFalse);
      expect(data.rawPeaks, isEmpty);
      expect(data.normalizedPeaks, isEmpty);
    });

    test('fromRaw builds raw and normalized peaks', () {
      final data = WaveformData.fromRaw([0, 5, 10]);

      expect(data.rawPeaks, [0.0, 5.0, 10.0]);
      expect(data.normalizedPeaks, [0.0, 0.5, 1.0]);
      expect(data.isNotEmpty, isTrue);
    });

    test('fromRaw with identical values normalizes to 0.5', () {
      final data = WaveformData.fromRaw([7, 7, 7]);

      expect(data.normalizedPeaks, [0.5, 0.5, 0.5]);
    });

    test('resample returns zeroes for empty waveform', () {
      const data = WaveformData.empty();

      expect(data.resample(4), [0.0, 0.0, 0.0, 0.0]);
    });

    test('resample returns same list when target count matches', () {
      final data = WaveformData.fromRaw([1, 2, 3]);

      expect(data.resample(3), data.normalizedPeaks);
    });

    test('resample downsamples by averaging slices', () {
      final data = WaveformData.fromRaw([0, 1, 2, 3]);

      final result = data.resample(2);
      expect(result.length, 2);
      expect(result[0], closeTo(0.1666, 0.01));
      expect(result[1], closeTo(0.8333, 0.01));
    });

    test('peakAt clamps progress bounds', () {
      final data = WaveformData.fromRaw([0, 10]);

      expect(data.peakAt(-10), 0.0);
      expect(data.peakAt(10), 1.0);
    });

    test('peakAt returns 0 for empty waveform', () {
      const data = WaveformData.empty();

      expect(data.peakAt(0.5), 0.0);
    });
  });
}
