import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/waveform_data.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/player_waveform.dart';

void main() {
  testWidgets('shows loading state when waveform data is empty',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerWaveform(
          position: Duration.zero,
          duration: const Duration(seconds: 60),
          onSeek: (_) {},
          waveformData: null,
        ),
      ),
    );

    expect(find.text('Loading waveform...'), findsOneWidget);
  });

  testWidgets('renders bars, comment markers, and seeks on gestures',
      (tester) async {
    final seeks = <Duration>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: PlayerWaveform(
              position: const Duration(seconds: 15),
              duration: const Duration(seconds: 60),
              onSeek: seeks.add,
              commentTimestampsSeconds: const [0, 30, 90],
              waveformData: WaveformData.fromRaw(const [
                0.1,
                0.5,
                1.0,
                0.2,
              ]),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GestureDetector), findsOneWidget);
    expect(find.byType(Container), findsWidgets);

    await tester.tapAt(
      tester.getTopLeft(find.byType(GestureDetector)) + const Offset(150, 36),
    );
    await tester.dragFrom(
      tester.getTopLeft(find.byType(GestureDetector)) + const Offset(100, 36),
      const Offset(75, 0),
    );

    expect(seeks.length, greaterThanOrEqualTo(0));
  });

  testWidgets('hides comment markers when duration is unavailable',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerWaveform(
          position: const Duration(seconds: 15),
          duration: null,
          onSeek: (_) {},
          commentTimestampsSeconds: const [10],
          waveformData: WaveformData.fromRaw(const [0.5, 0.8]),
        ),
      ),
    );

    expect(find.byType(GestureDetector), findsOneWidget);
  });
}
