import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/data/repositories/profileRepositoryFake.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/ProfileImageUploadResult.dart';

void main() {
  group('ProfileRepositoryFake', () {
    final Uint8List bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    test('success mode uploads successfully and reports progress', () async {
      final repository = ProfileRepositoryFake(
        mode: MockProfileImageUploadMode.success,
      );

      final List<int> sentValues = <int>[];
      final List<int> totalValues = <int>[];

      final result = await repository.uploadProfileImage(
        type: ProfileImageType.avatar,
        fileName: 'avatar.jpg',
        fileBytes: bytes,
        mimeType: 'image/jpeg',
        onProgress: (sent, total) {
          sentValues.add(sent);
          totalValues.add(total);
        },
      );

      expect(result.type, ProfileImageType.avatar);
      expect(result.url, contains('mock://avatar/avatar.jpg'));
      expect(result.key, startsWith('mock_avatar_'));
      expect(sentValues, [15, 35, 60, 85, 100]);
      expect(totalValues, everyElement(100));
    });

    test('alwaysFail mode throws exception', () async {
      final repository = ProfileRepositoryFake(
        mode: MockProfileImageUploadMode.alwaysFail,
      );

      expect(
        () => repository.uploadProfileImage(
          type: ProfileImageType.cover,
          fileName: 'cover.jpg',
          fileBytes: bytes,
          mimeType: 'image/jpeg',
        ),
        throwsA(
          isA<Exception>().having(
            (exception) => exception.toString(),
            'message',
            contains('Mock upload failed'),
          ),
        ),
      );
    });

    test('failOnce mode fails first then succeeds on second attempt', () async {
      final repository = ProfileRepositoryFake(
        mode: MockProfileImageUploadMode.failOnce,
      );

      expect(
        () => repository.uploadProfileImage(
          type: ProfileImageType.cover,
          fileName: 'cover.jpg',
          fileBytes: bytes,
          mimeType: 'image/jpeg',
        ),
        throwsA(
          isA<Exception>().having(
            (exception) => exception.toString(),
            'message',
            contains('Mock upload failed once'),
          ),
        ),
      );

      final result = await repository.uploadProfileImage(
        type: ProfileImageType.cover,
        fileName: 'cover.jpg',
        fileBytes: bytes,
        mimeType: 'image/jpeg',
      );

      expect(result.type, ProfileImageType.cover);
      expect(result.url, contains('mock://cover/cover.jpg'));
      expect(result.key, startsWith('mock_cover_'));
    });
  });
}
