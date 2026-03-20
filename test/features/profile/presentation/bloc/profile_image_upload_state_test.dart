import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/ProfileImageUploadResult.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profileImageUploadState.dart';

void main() {
  group('ProfileImageUploadState', () {
    final Uint8List previewBytes = Uint8List.fromList([1, 2, 3, 4]);

    const uploadResult = ProfileImageUploadResult(
      type: ProfileImageType.avatar,
      url: 'mock://avatar/avatar.jpg',
      key: 'avatar-key',
    );

    test('hasPreparedImage is false by default', () {
      const state = ProfileImageUploadState();

      expect(state.hasPreparedImage, isFalse);
      expect(state.status, ProfileImageUploadStatus.initial);
    });

    test('hasPreparedImage is true when required fields are present', () {
      final state = ProfileImageUploadState(
        status: ProfileImageUploadStatus.ready,
        activeImageType: ProfileImageType.avatar,
        previewBytes: previewBytes,
        selectedFileName: 'avatar.jpg',
        selectedMimeType: 'image/jpeg',
      );

      expect(state.hasPreparedImage, isTrue);
    });

    test('copyWith updates provided values', () {
      final state = ProfileImageUploadState(
        status: ProfileImageUploadStatus.ready,
        activeImageType: ProfileImageType.avatar,
        previewBytes: previewBytes,
        selectedFileName: 'avatar.jpg',
        selectedMimeType: 'image/jpeg',
        selectedFileSizeInBytes: 2048,
      );

      final next = state.copyWith(
        status: ProfileImageUploadStatus.success,
        uploadProgress: 1.0,
        lastUploadResult: uploadResult,
        currentAvatarUrl: 'https://cdn.example.com/avatar.jpg',
        currentAvatarBytes: previewBytes,
      );

      expect(next.status, ProfileImageUploadStatus.success);
      expect(next.uploadProgress, 1.0);
      expect(next.lastUploadResult, uploadResult);
      expect(next.currentAvatarUrl, 'https://cdn.example.com/avatar.jpg');
      expect(next.currentAvatarBytes, previewBytes);
      expect(next.selectedFileName, 'avatar.jpg');
    });

    test('copyWith clears prepared image when clearPreparedImage is true', () {
      final state = ProfileImageUploadState(
        status: ProfileImageUploadStatus.ready,
        activeImageType: ProfileImageType.cover,
        previewBytes: previewBytes,
        selectedFileName: 'cover.jpg',
        selectedMimeType: 'image/jpeg',
        selectedFileSizeInBytes: 4096,
      );

      final next = state.copyWith(
        clearPreparedImage: true,
      );

      expect(next.activeImageType, isNull);
      expect(next.previewBytes, isNull);
      expect(next.selectedFileName, isNull);
      expect(next.selectedMimeType, isNull);
      expect(next.selectedFileSizeInBytes, isNull);
    });

    test('copyWith clears result and error when requested', () {
      const state = ProfileImageUploadState(
        status: ProfileImageUploadStatus.failure,
        lastUploadResult: uploadResult,
        errorMessage: 'Something went wrong',
      );

      final next = state.copyWith(
        clearLastUploadResult: true,
        clearErrorMessage: true,
      );

      expect(next.lastUploadResult, isNull);
      expect(next.errorMessage, isNull);
    });
  });
}
