import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/picked_audio_file.dart';
import 'package:soundcloud_clone/features/upload/presentation/widgets/selected_audio_file_card.dart';

void main() {
  group('SelectedAudioFileCard', () {
    testWidgets('renders selected file metadata with path', (tester) async {
      const pickedAudioFile = PickedAudioFile(
        name: 'song.mp3',
        extension: 'mp3',
        sizeInBytes: 2048,
        path: '/storage/emulated/0/Download/song.mp3',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SelectedAudioFileCard(
              pickedAudioFile: pickedAudioFile,
            ),
          ),
        ),
      );

      expect(find.text('Name: song.mp3'), findsOneWidget);
      expect(find.text('Extension: MP3'), findsOneWidget);
      expect(find.text('Size: 2.0 KB'), findsOneWidget);
      expect(
        find.text('Path: /storage/emulated/0/Download/song.mp3'),
        findsOneWidget,
      );
    });

    testWidgets('renders unavailable path when file path is null',
        (tester) async {
      const pickedAudioFile = PickedAudioFile(
        name: 'song.wav',
        extension: 'wav',
        sizeInBytes: 1024,
        path: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SelectedAudioFileCard(
              pickedAudioFile: pickedAudioFile,
            ),
          ),
        ),
      );

      expect(find.text('Name: song.wav'), findsOneWidget);
      expect(find.text('Extension: WAV'), findsOneWidget);
      expect(find.text('Size: 1.0 KB'), findsOneWidget);
      expect(find.text('Path: Unavailable on this platform'), findsOneWidget);
    });
  });
}
