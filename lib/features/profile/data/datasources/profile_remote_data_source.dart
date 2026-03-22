// Dart SDK
// Flutter
// Third-party
import 'package:dio/dio.dart';

// Project
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/profile_repository.dart';
import '../dto/profile_dto.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileDto> getProfile(String handle);
  Future<ProfileDto> updateProfile(Map<String, dynamic> body);
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  });
  Future<bool> checkHandleAvailable(String handle);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient _dioClient;

  const ProfileRemoteDataSourceImpl(this._dioClient);

  /// GET /api/v1/profiles/:handle
  /// No auth required — public endpoint.
  /// Returns full profile JSON including bio, location, genres, etc.
  @override
  Future<ProfileDto> getProfile(String handle) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      '${ApiConstants.profileByHandle}/$handle',
    );
    return ProfileDto.fromJson(response.data!);
  }

  /// PATCH /api/v1/profiles/me
  /// Auth required — JWT cookie sent automatically by CookieManager.
  /// Only sends fields that are non-null (partial update).
  /// Returns the full updated profile object.
  @override
  Future<ProfileDto> updateProfile(Map<String, dynamic> body) async {
    final response = await _dioClient.patch<Map<String, dynamic>>(
      ApiConstants.myProfile,
      data: body,
    );
    return ProfileDto.fromJson(response.data!);
  }

  /// POST /api/v1/profiles/me/images/avatar
  /// POST /api/v1/profiles/me/images/cover
  /// Auth required.
  /// Sends the image file as multipart/form-data.
  /// Field name must be exactly 'file' — as required by the API doc.
  /// Returns: { "message": "...", "url": "https://s3.aws.com/..." }
  @override
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  }) async {
    // Convert enum to the exact string the API path expects
    final typeString =
        imageType == ProfileImageType.AVATAR ? 'avatar' : 'cover';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _dioClient.post<Map<String, dynamic>>(
      '${ApiConstants.profileImages}/$typeString',
      data: formData,
      // Override Content-Type for this specific request only —
      // multipart/form-data replaces the default application/json
      options: Options(contentType: 'multipart/form-data'),
    );

    // API returns { "message": "Image uploaded successfully", "url": "https://..." }
    return response.data!['url'] as String;
  }

  /// GET /api/v1/profiles/check-handle?handle=xxx
  /// Auth required.
  /// Returns: { "handle": "...", "available": true/false, "message": "..." }
  @override
  Future<bool> checkHandleAvailable(String handle) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      ApiConstants.checkHandle,
      queryParameters: {'handle': handle},
    );
    return response.data!['available'] as bool;
  }
}
