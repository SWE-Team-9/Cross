import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/data/repositories/profileRepositoryFake.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/ProfileImageUploadResult.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/uploadProfileImageUseCase.dart';

void main() {
  group('UploadProfileImageUseCase', () {
    final Uint8List bytes = Uint8List.fromList([1, 2, 3]);

    test('delegates upload to repository and returns result', () async {
      final useCase = UploadProfileImageUseCase(
        ProfileRepositoryFake(
          mode: MockProfileImageUploadMode.success,
        ),
      );

      final result = await useCase(
        type: ProfileImageType.avatar,
        fileName: 'avatar.jpg',
        fileBytes: bytes,
        mimeType: 'image/jpeg',
      );

      expect(result.type, ProfileImageType.avatar);
      expect(result.url, contains('mock://avatar/avatar.jpg'));
    });

    test('propagates repository exceptions', () async {
      final useCase = UploadProfileImageUseCase(
        ProfileRepositoryFake(
          mode: MockProfileImageUploadMode.alwaysFail,
        ),
      );

      expect(
        () => useCase(
          type: ProfileImageType.cover,
          fileName: 'cover.jpg',
          fileBytes: bytes,
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
