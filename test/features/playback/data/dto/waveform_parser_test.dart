import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/playback/data/dto/waveform_parser.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/waveform_data.dart';

void main() {
  group('WaveformParser', () {
    test('returns empty when waveformData is missing', () {
      final data = WaveformParser.fromTrackJson(const {'id': 't1'});

      expect(data, const WaveformData.empty());
    });

    test('returns empty when waveformData is not a list', () {
      final data = WaveformParser.fromTrackJson(const {'waveformData': 'bad'});

      expect(data, const WaveformData.empty());
    });

    test('returns empty when waveformData list is empty', () {
      final data = WaveformParser.fromTrackJson(const {'waveformData': []});

      expect(data, const WaveformData.empty());
    });

    test('parses waveformData list', () {
      final data = WaveformParser.fromTrackJson(const {
        'waveformData': [0, 2, 4]
      });

      expect(data.rawPeaks, [0.0, 2.0, 4.0]);
      expect(data.isNotEmpty, isTrue);
    });

    test('returns empty when list contains invalid value', () {
      final data = WaveformParser.fromTrackJson(const {
        'waveformData': [0, 'x', 4]
      });

      expect(data, const WaveformData.empty());
    });
  });
}
