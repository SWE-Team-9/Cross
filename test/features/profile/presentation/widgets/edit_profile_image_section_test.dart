import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/edit_profile_image_section.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester, {
    String? avatarUrl,
    String? coverUrl,
    bool isUploadingAvatar = false,
    bool isUploadingCover = false,
    required void Function(ProfileImageType) onPickImage,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditProfileImageSection(
            avatarUrl: avatarUrl,
            coverUrl: coverUrl,
            isUploadingAvatar: isUploadingAvatar,
            isUploadingCover: isUploadingCover,
            onPickImage: onPickImage,
          ),
        ),
      ),
    );
  }

  group('EditProfileImageSection', () {
    testWidgets('tapping cover area triggers cover picker', (tester) async {
      ProfileImageType? pickedType;

      await pumpSection(
        tester,
        onPickImage: (type) => pickedType = type,
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(pickedType, ProfileImageType.COVER);
    });

    testWidgets('tapping cover camera badge triggers cover picker',
        (tester) async {
      ProfileImageType? pickedType;

      await pumpSection(
        tester,
        onPickImage: (type) => pickedType = type,
      );

      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pump();

      expect(pickedType, ProfileImageType.COVER);
    });

    testWidgets('tapping avatar camera triggers avatar picker', (tester) async {
      ProfileImageType? pickedType;

      await pumpSection(
        tester,
        onPickImage: (type) => pickedType = type,
      );

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();

      expect(pickedType, ProfileImageType.AVATAR);
    });

    testWidgets('shows placeholder avatar icon when avatar url is null',
        (tester) async {
      await pumpSection(
        tester,
        avatarUrl: null,
        onPickImage: (_) {},
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows cover upload overlay and disables cover interactions',
        (tester) async {
      await pumpSection(
        tester,
        isUploadingCover: true,
        onPickImage: (_) {},
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
    });

    testWidgets('shows avatar upload overlay and disables avatar tap',
        (tester) async {
      await pumpSection(
        tester,
        isUploadingAvatar: true,
        onPickImage: (_) {},
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsNothing);
    });

    testWidgets('builds avatar and cover image branches when urls are provided',
        (tester) async {
      await pumpSection(
        tester,
        avatarUrl: 'https://example.com/avatar.png',
        coverUrl: 'https://example.com/cover.png',
        onPickImage: (_) {},
      );

      await tester.pump();

      final exception = tester.takeException();
      expect(exception, isNull);

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });
  });
}
