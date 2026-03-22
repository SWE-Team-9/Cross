import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/ProfileImageUploadResult.dart';
import '../../domain/usecases/uploadProfileImageUseCase.dart';
import 'profileImageUploadState.dart';

class ProfileImageUploadCubit extends Cubit<ProfileImageUploadState> {
  ProfileImageUploadCubit(
    this._uploadProfileImageUseCase, {
    ImagePicker? imagePicker,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        super(const ProfileImageUploadState());

  final UploadProfileImageUseCase _uploadProfileImageUseCase;
  final ImagePicker _imagePicker;

  Future<void> pickImage({
    required ProfileImageType type,
    required ImageSource source,
  }) async {
    emit(
      state.copyWith(
        status: ProfileImageUploadStatus.preparing,
        activeImageType: type,
        uploadProgress: 0.0,
        clearPreparedImage: true,
        clearLastUploadResult: true,
        clearErrorMessage: true,
      ),
    );

    try {
      if (source == ImageSource.camera && !_supportsCameraCapture()) {
        emit(
          state.copyWith(
            status: ProfileImageUploadStatus.failure,
            errorMessage:
                'Camera capture is not supported on this platform yet. Please choose an image from gallery.',
            clearPreparedImage: true,
            clearLastUploadResult: true,
          ),
        );
        return;
      }

      final XFile? pickedFile = await _imagePicker.pickImage(source: source);

      if (pickedFile == null) {
        emit(
          state.copyWith(
            status: ProfileImageUploadStatus.initial,
            clearPreparedImage: true,
            clearLastUploadResult: true,
            clearErrorMessage: true,
          ),
        );
        return;
      }

      final _PreparedProfileImage? preparedImage = await _prepareImageForUpload(
        pickedFile: pickedFile,
        type: type,
      );

      if (preparedImage == null) {
        emit(
          state.copyWith(
            status: ProfileImageUploadStatus.initial,
            clearPreparedImage: true,
            clearLastUploadResult: true,
            clearErrorMessage: true,
          ),
        );
        return;
      }

      if (preparedImage.bytes.lengthInBytes > type.maxFileSizeInBytes) {
        emit(
          state.copyWith(
            status: ProfileImageUploadStatus.failure,
            errorMessage:
                '${type.displayName} image is too large. Maximum allowed size is ${_formatBytes(type.maxFileSizeInBytes)}.',
            clearPreparedImage: true,
            clearLastUploadResult: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: ProfileImageUploadStatus.ready,
          activeImageType: type,
          previewBytes: preparedImage.bytes,
          selectedFileName: preparedImage.fileName,
          selectedMimeType: preparedImage.mimeType,
          selectedFileSizeInBytes: preparedImage.bytes.lengthInBytes,
          uploadProgress: 0.0,
          clearLastUploadResult: true,
          clearErrorMessage: true,
        ),
      );
    } catch (exception) {
      emit(
        state.copyWith(
          status: ProfileImageUploadStatus.failure,
          errorMessage: kDebugMode
              ? 'Unable to prepare ${type.displayName.toLowerCase()} image. ${exception.toString().replaceFirst('Exception: ', '')}'
              : 'Unable to prepare ${type.displayName.toLowerCase()} image. Please try again.',
          clearPreparedImage: true,
          clearLastUploadResult: true,
        ),
      );
    }
  }

  Future<void> uploadSelectedImage() async {
    if (!state.hasPreparedImage || state.activeImageType == null) {
      emit(
        state.copyWith(
          status: ProfileImageUploadStatus.failure,
          errorMessage: 'Please select an image first.',
        ),
      );
      return;
    }

    final ProfileImageType uploadType = state.activeImageType!;
    final Uint8List preparedBytes = state.previewBytes!;
    final String preparedFileName = state.selectedFileName!;
    final String preparedMimeType = state.selectedMimeType!;

    emit(
      state.copyWith(
        status: ProfileImageUploadStatus.uploading,
        uploadProgress: 0.0,
        clearLastUploadResult: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final ProfileImageUploadResult result = await _uploadProfileImageUseCase(
        type: uploadType,
        fileName: preparedFileName,
        fileBytes: preparedBytes,
        mimeType: preparedMimeType,
        onProgress: (int sent, int total) {
          final double progress =
              total <= 0 ? 0.0 : (sent / total).clamp(0.0, 1.0).toDouble();

          emit(
            state.copyWith(
              status: ProfileImageUploadStatus.uploading,
              uploadProgress: progress,
            ),
          );
        },
      );

      emit(
        state.copyWith(
          status: ProfileImageUploadStatus.success,
          uploadProgress: 1.0,
          lastUploadResult: result,
          currentAvatarUrl: uploadType == ProfileImageType.avatar
              ? result.url
              : state.currentAvatarUrl,
          currentCoverUrl: uploadType == ProfileImageType.cover
              ? result.url
              : state.currentCoverUrl,
          currentAvatarBytes: uploadType == ProfileImageType.avatar
              ? preparedBytes
              : state.currentAvatarBytes,
          currentCoverBytes: uploadType == ProfileImageType.cover
              ? preparedBytes
              : state.currentCoverBytes,
          clearPreparedImage: true,
          clearErrorMessage: true,
        ),
      );
    } catch (exception) {
      emit(
        state.copyWith(
          status: ProfileImageUploadStatus.failure,
          errorMessage: exception.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> retryUpload() async {
    await uploadSelectedImage();
  }

  void clearSelection() {
    emit(
      state.copyWith(
        status: ProfileImageUploadStatus.initial,
        uploadProgress: 0.0,
        clearPreparedImage: true,
        clearLastUploadResult: true,
        clearErrorMessage: true,
      ),
    );
  }

  Future<_PreparedProfileImage?> _prepareImageForUpload({
    required XFile pickedFile,
    required ProfileImageType type,
  }) async {
    if (_shouldUseOriginalDesktopImage()) {
      final Uint8List originalBytes = await pickedFile.readAsBytes();
      final String mimeType = _inferMimeTypeFromFileName(pickedFile.name);
      final String fileName = _normalizePickedFileName(
        originalName: pickedFile.name,
        fallbackType: type,
      );

      return _PreparedProfileImage(
        bytes: originalBytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    }

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: CropAspectRatio(
        ratioX: type == ProfileImageType.avatar ? 1 : 16,
        ratioY: type == ProfileImageType.avatar ? 1 : 9,
      ),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop ${type.displayName}',
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop ${type.displayName}',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) {
      return null;
    }

    final Uint8List croppedBytes = await XFile(croppedFile.path).readAsBytes();
    final Uint8List optimizedBytes = await _compressImage(
      inputBytes: croppedBytes,
      type: type,
    );

    return _PreparedProfileImage(
      bytes: optimizedBytes,
      fileName: _buildUploadFileName(type),
      mimeType: 'image/jpeg',
    );
  }

  bool _shouldUseOriginalDesktopImage() {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  bool _supportsCameraCapture() {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<Uint8List> _compressImage({
    required Uint8List inputBytes,
    required ProfileImageType type,
  }) async {
    final Uint8List result = await FlutterImageCompress.compressWithList(
      inputBytes,
      minWidth: type == ProfileImageType.avatar ? 512 : 1600,
      minHeight: type == ProfileImageType.avatar ? 512 : 900,
      quality: 85,
      format: CompressFormat.jpeg,
    );

    return result;
  }

  String _buildUploadFileName(ProfileImageType type) {
    return '${type.name}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  String _normalizePickedFileName({
    required String originalName,
    required ProfileImageType fallbackType,
  }) {
    final String trimmed = originalName.trim();

    if (trimmed.isNotEmpty && trimmed.contains('.')) {
      return trimmed;
    }

    final String fallbackExtension =
        fallbackType == ProfileImageType.avatar ? 'jpg' : 'jpg';

    return '${fallbackType.name}_${DateTime.now().millisecondsSinceEpoch}.$fallbackExtension';
  }

  String _inferMimeTypeFromFileName(String fileName) {
    final String lower = fileName.toLowerCase();

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _PreparedProfileImage {
  const _PreparedProfileImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}
