import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profileImageUploadState.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/ProfileImageUploadProgress.dart';

void main() {
  group('ProfileImageUploadProgress', () {
    testWidgets('renders determinate progress while uploading', (tester) async {
      const state = ProfileImageUploadState(
        status: ProfileImageUploadStatus.uploading,
        uploadProgress: 0.5,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileImageUploadProgress(
              state: state,
            ),
          ),
        ),
      );

      expect(find.text('Uploading image...'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders indeterminate upload text when progress is zero',
        (tester) async {
      const state = ProfileImageUploadState(
        status: ProfileImageUploadStatus.uploading,
        uploadProgress: 0.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileImageUploadProgress(
              state: state,
            ),
          ),
        ),
      );

      expect(find.text('Preparing upload...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders nothing when status is not uploading', (tester) async {
      const state = ProfileImageUploadState(
        status: ProfileImageUploadStatus.initial,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileImageUploadProgress(
              state: state,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Uploading image...'), findsNothing);
    });
  });
}
