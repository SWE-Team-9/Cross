import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/data/repositories/profileRepositoryFake.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/ProfileImageUploadResult.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/uploadProfileImageUseCase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profileImageUploadCubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profileImageUploadState.dart';

class TestProfileImageUploadCubit extends ProfileImageUploadCubit {
  TestProfileImageUploadCubit(super.uploadProfileImageUseCase);

  void seed(ProfileImageUploadState state) {
    emit(state);
  }
}

void main() {
  group('ProfileImageUploadCubit', () {
    late Uint8List bytes;

    setUp(() {
      bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
    });

    test('initial state is correct', () {
      final cubit = TestProfileImageUploadCubit(
        UploadProfileImageUseCase(
          ProfileRepositoryFake(
            mode: MockProfileImageUploadMode.success,
          ),
        ),
      );

      expect(cubit.state, const ProfileImageUploadState());

      cubit.close();
    });

    test('uploadSelectedImage succeeds for avatar', () async {
      final cubit = TestProfileImageUploadCubit(
        UploadProfileImageUseCase(
          ProfileRepositoryFake(
            mode: MockProfileImageUploadMode.success,
          ),
        ),
      );

      cubit.seed(
        ProfileImageUploadState(
          status: ProfileImageUploadStatus.ready,
          activeImageType: ProfileImageType.avatar,
          previewBytes: bytes,
          selectedFileName: 'avatar.jpg',
          selectedMimeType: 'image/jpeg',
          selectedFileSizeInBytes: bytes.lengthInBytes,
        ),
      );

      await cubit.uploadSelectedImage();

      expect(cubit.state.status, ProfileImageUploadStatus.success);
      expect(cubit.state.lastUploadResult, isNotNull);
      expect(
          cubit.state.currentAvatarUrl, contains('mock://avatar/avatar.jpg'));
      expect(cubit.state.currentAvatarBytes, bytes);
      expect(cubit.state.previewBytes, isNull);
      expect(cubit.state.uploadProgress, 1.0);

      await cubit.close();
    });

    test('uploadSelectedImage fails for alwaysFail mode', () async {
      final cubit = TestProfileImageUploadCubit(
        UploadProfileImageUseCase(
          ProfileRepositoryFake(
            mode: MockProfileImageUploadMode.alwaysFail,
          ),
        ),
      );

      cubit.seed(
        ProfileImageUploadState(
          status: ProfileImageUploadStatus.ready,
          activeImageType: ProfileImageType.cover,
          previewBytes: bytes,
          selectedFileName: 'cover.jpg',
          selectedMimeType: 'image/jpeg',
          selectedFileSizeInBytes: bytes.lengthInBytes,
        ),
      );

      await cubit.uploadSelectedImage();

      expect(cubit.state.status, ProfileImageUploadStatus.failure);
      expect(cubit.state.errorMessage, contains('Mock upload failed'));
      expect(cubit.state.previewBytes, isNotNull);

      await cubit.close();
    });

    test('retryUpload succeeds after failOnce mode initial failure', () async {
      final cubit = TestProfileImageUploadCubit(
        UploadProfileImageUseCase(
          ProfileRepositoryFake(
            mode: MockProfileImageUploadMode.failOnce,
          ),
        ),
      );

      cubit.seed(
        ProfileImageUploadState(
          status: ProfileImageUploadStatus.ready,
          activeImageType: ProfileImageType.cover,
          previewBytes: bytes,
          selectedFileName: 'cover.jpg',
          selectedMimeType: 'image/jpeg',
          selectedFileSizeInBytes: bytes.lengthInBytes,
        ),
      );

      await cubit.uploadSelectedImage();

      expect(cubit.state.status, ProfileImageUploadStatus.failure);
      expect(cubit.state.errorMessage, contains('Mock upload failed once'));

      await cubit.retryUpload();

      expect(cubit.state.status, ProfileImageUploadStatus.success);
      expect(cubit.state.currentCoverUrl, contains('mock://cover/cover.jpg'));
      expect(cubit.state.currentCoverBytes, bytes);
      expect(cubit.state.lastUploadResult, isA<ProfileImageUploadResult>());

      await cubit.close();
    });

    test('clearSelection resets prepared state fields', () async {
      final cubit = TestProfileImageUploadCubit(
        UploadProfileImageUseCase(
          ProfileRepositoryFake(
            mode: MockProfileImageUploadMode.success,
          ),
        ),
      );

      cubit.seed(
        ProfileImageUploadState(
          status: ProfileImageUploadStatus.ready,
          activeImageType: ProfileImageType.avatar,
          previewBytes: bytes,
          selectedFileName: 'avatar.jpg',
          selectedMimeType: 'image/jpeg',
          selectedFileSizeInBytes: bytes.lengthInBytes,
          errorMessage: 'Old error',
        ),
      );

      cubit.clearSelection();

      expect(cubit.state.status, ProfileImageUploadStatus.initial);
      expect(cubit.state.previewBytes, isNull);
      expect(cubit.state.selectedFileName, isNull);
      expect(cubit.state.selectedMimeType, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.lastUploadResult, isNull);

      await cubit.close();
    });

    test('uploadSelectedImage fails when no prepared image exists', () async {
      final cubit = TestProfileImageUploadCubit(
        UploadProfileImageUseCase(
          ProfileRepositoryFake(
            mode: MockProfileImageUploadMode.success,
          ),
        ),
      );

      await cubit.uploadSelectedImage();

      expect(cubit.state.status, ProfileImageUploadStatus.failure);
      expect(cubit.state.errorMessage, 'Please select an image first.');

      await cubit.close();
    });
  });
}
