import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/edit_profile_image_section.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: child,
      ),
    );
  }

  group('EditProfileImageSection', () {
    testWidgets('renders default placeholders when avatar and cover are null',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EditProfileImageSection(
            avatarUrl: null,
            coverUrl: null,
            isUploadingAvatar: false,
            isUploadingCover: false,
            onPickImage: (_) {},
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('calls onPickImage with cover when cover camera is tapped',
        (tester) async {
      ProfileImageType? pickedType;

      await tester.pumpWidget(
        wrap(
          EditProfileImageSection(
            avatarUrl: null,
            coverUrl: null,
            isUploadingAvatar: false,
            isUploadingCover: false,
            onPickImage: (type) => pickedType = type,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pump();

      expect(pickedType, ProfileImageType.COVER);
    });

    testWidgets('calls onPickImage with avatar when avatar area is tapped',
        (tester) async {
      ProfileImageType? pickedType;

      await tester.pumpWidget(
        wrap(
          EditProfileImageSection(
            avatarUrl: null,
            coverUrl: null,
            isUploadingAvatar: false,
            isUploadingCover: false,
            onPickImage: (type) => pickedType = type,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();

      expect(pickedType, ProfileImageType.AVATAR);
    });

    testWidgets('shows upload progress indicator for avatar when uploading',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EditProfileImageSection(
            avatarUrl: null,
            coverUrl: null,
            isUploadingAvatar: true,
            isUploadingCover: false,
            onPickImage: (_) {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsNothing);
    });

    testWidgets('shows upload progress indicator for cover when uploading',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EditProfileImageSection(
            avatarUrl: null,
            coverUrl: null,
            isUploadingAvatar: false,
            isUploadingCover: true,
            onPickImage: (_) {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
    });

    testWidgets(
        'shows two progress indicators when both avatar and cover upload',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EditProfileImageSection(
            avatarUrl: null,
            coverUrl: null,
            isUploadingAvatar: true,
            isUploadingCover: true,
            onPickImage: (_) {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    });
  });
}
