import 'package:dio/dio.dart';

// Project
import '../../domain/repositories/profile_repository.dart';
import '../dto/profile_dto.dart';

/// Abstract contract for the profile HTTP data source.
abstract class ProfileRemoteDataSource {
  Future<ProfileDto> getProfile(String handle);
  Future<ProfileDto> updateProfile(Map<String, dynamic> body);
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  });
  Future<bool> checkHandleAvailable(String handle);
}

/// Concrete implementation — makes real Dio HTTP calls.
/// Does NOT catch exceptions — that is the Repository's responsibility.
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio _dio;

  const ProfileRemoteDataSourceImpl(this._dio);

  /// GET /api/v1/profiles/:handle
  @override
  Future<ProfileDto> getProfile(String handle) async {
    final response = await _dio.get('/api/v1/profiles/$handle');
    return ProfileDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /api/v1/profiles/me
  /// Body contains only the fields that were changed.
  @override
  Future<ProfileDto> updateProfile(Map<String, dynamic> body) async {
    final response = await _dio.patch('/api/v1/profiles/me', data: body);
    return ProfileDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/v1/profiles/me/images/:type
  /// Sends file as multipart/form-data — field name must be 'file'.
  @override
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  }) async {
    final typeString =
        imageType == ProfileImageType.AVATAR ? 'avatar' : 'cover';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _dio.post(
      '/api/v1/profiles/me/images/$typeString',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    // API returns: { "message": "...", "url": "https://..." }
    return response.data['url'] as String;
  }

  /// GET /api/v1/profiles/check-handle?handle=xxx
  /// API returns: { "handle": "...", "available": true, "message": "..." }
  @override
  Future<bool> checkHandleAvailable(String handle) async {
    final response = await _dio.get(
      '/api/v1/profiles/check-handle',
      queryParameters: {'handle': handle},
    );
    return response.data['available'] as bool;
  }
}
