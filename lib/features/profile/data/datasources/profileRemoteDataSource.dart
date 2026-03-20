import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/ProfileImageUploadResult.dart';
import '../../domain/repositories/profileRepository.dart';
import '../dto/ProfileImageUploadResponseDto.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileImageUploadResponseDto> uploadProfileImage({
    required ProfileImageType type,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    UploadProgressCallback? onProgress,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<ProfileImageUploadResponseDto> uploadProfileImage({
    required ProfileImageType type,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final FormData formData = FormData.fromMap(
        {
          'file': MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
            contentType: DioMediaType.parse(mimeType),
          ),
        },
      );

      final Response<dynamic> response = await _dioClient.dio.post(
        '/profiles/me/${type.endpointSegment}',
        data: formData,
        onSendProgress: onProgress,
      );

      final Map<String, dynamic> normalizedPayload =
          _normalizeResponsePayload(response.data);

      return ProfileImageUploadResponseDto.fromJson(normalizedPayload);
    } on DioException catch (exception) {
      throw Exception(_extractErrorMessage(exception));
    } catch (exception) {
      throw Exception(
          'Failed to upload ${type.displayName.toLowerCase()} image.');
    }
  }

  Map<String, dynamic> _normalizeResponsePayload(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid upload response received from server.');
    }

    final dynamic nestedData = responseData['data'];

    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }

    return responseData;
  }

  String _extractErrorMessage(DioException exception) {
    final dynamic responseData = exception.response?.data;

    if (responseData is Map<String, dynamic>) {
      final dynamic message = responseData['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return 'Profile image upload failed. Please try again.';
  }
}
