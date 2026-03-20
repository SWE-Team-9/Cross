import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../domain/entities/ProfileImageUploadResult.dart';

enum ProfileImageUploadStatus {
  initial,
  preparing,
  ready,
  uploading,
  success,
  failure,
}

class ProfileImageUploadState extends Equatable {
  const ProfileImageUploadState({
    this.status = ProfileImageUploadStatus.initial,
    this.activeImageType,
    this.previewBytes,
    this.selectedFileName,
    this.selectedMimeType,
    this.selectedFileSizeInBytes,
    this.uploadProgress = 0.0,
    this.lastUploadResult,
    this.currentAvatarUrl,
    this.currentCoverUrl,
    this.currentAvatarBytes,
    this.currentCoverBytes,
    this.errorMessage,
  });

  final ProfileImageUploadStatus status;
  final ProfileImageType? activeImageType;
  final Uint8List? previewBytes;
  final String? selectedFileName;
  final String? selectedMimeType;
  final int? selectedFileSizeInBytes;
  final double uploadProgress;
  final ProfileImageUploadResult? lastUploadResult;
  final String? currentAvatarUrl;
  final String? currentCoverUrl;
  final Uint8List? currentAvatarBytes;
  final Uint8List? currentCoverBytes;
  final String? errorMessage;

  bool get hasPreparedImage =>
      previewBytes != null &&
      activeImageType != null &&
      selectedFileName != null &&
      selectedMimeType != null;

  ProfileImageUploadState copyWith({
    ProfileImageUploadStatus? status,
    ProfileImageType? activeImageType,
    Uint8List? previewBytes,
    String? selectedFileName,
    String? selectedMimeType,
    int? selectedFileSizeInBytes,
    double? uploadProgress,
    ProfileImageUploadResult? lastUploadResult,
    String? currentAvatarUrl,
    String? currentCoverUrl,
    Uint8List? currentAvatarBytes,
    Uint8List? currentCoverBytes,
    String? errorMessage,
    bool clearPreparedImage = false,
    bool clearLastUploadResult = false,
    bool clearErrorMessage = false,
  }) {
    return ProfileImageUploadState(
      status: status ?? this.status,
      activeImageType:
          clearPreparedImage ? null : (activeImageType ?? this.activeImageType),
      previewBytes:
          clearPreparedImage ? null : (previewBytes ?? this.previewBytes),
      selectedFileName: clearPreparedImage
          ? null
          : (selectedFileName ?? this.selectedFileName),
      selectedMimeType: clearPreparedImage
          ? null
          : (selectedMimeType ?? this.selectedMimeType),
      selectedFileSizeInBytes: clearPreparedImage
          ? null
          : (selectedFileSizeInBytes ?? this.selectedFileSizeInBytes),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      lastUploadResult: clearLastUploadResult
          ? null
          : (lastUploadResult ?? this.lastUploadResult),
      currentAvatarUrl: currentAvatarUrl ?? this.currentAvatarUrl,
      currentCoverUrl: currentCoverUrl ?? this.currentCoverUrl,
      currentAvatarBytes: currentAvatarBytes ?? this.currentAvatarBytes,
      currentCoverBytes: currentCoverBytes ?? this.currentCoverBytes,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeImageType,
        previewBytes,
        selectedFileName,
        selectedMimeType,
        selectedFileSizeInBytes,
        uploadProgress,
        lastUploadResult,
        currentAvatarUrl,
        currentCoverUrl,
        currentAvatarBytes,
        currentCoverBytes,
        errorMessage,
      ];
}
