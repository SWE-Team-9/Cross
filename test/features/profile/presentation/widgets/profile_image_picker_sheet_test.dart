import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/ProfileImagePickerSheet.dart';

void main() {
  group('ProfileImagePickerSheet', () {
    testWidgets('renders title and triggers callbacks', (tester) async {
      int galleryTapCount = 0;
      int cameraTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImagePickerSheet(
              title: 'Change Avatar',
              onGalleryTap: () => galleryTapCount++,
              onCameraTap: () => cameraTapCount++,
            ),
          ),
        ),
      );

      expect(find.text('Change Avatar'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
      expect(find.text('Take a photo'), findsOneWidget);

      await tester.tap(find.text('Choose from gallery'));
      await tester.pump();

      await tester.tap(find.text('Take a photo'));
      await tester.pump();

      expect(galleryTapCount, 1);
      expect(cameraTapCount, 1);
    });
  });
}
