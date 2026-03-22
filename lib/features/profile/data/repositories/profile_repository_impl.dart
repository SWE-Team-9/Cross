import 'package:dio/dio.dart';

// Project
import '../../../../core/errors/failure.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

/// Catches DioException → throws typed Failure subclasses.
/// Converts DTOs → Entities before returning.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  const ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProfileEntity> getProfile(String handle) async {
    try {
      final dto = await _remoteDataSource.getProfile(handle);
      return dto.toEntity();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
    // No generic catch — unexpected errors propagate naturally.
    // The Cubit has a fallback catch for unexpected errors.
  }

  @override
  Future<ProfileEntity> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    List<String>? favoriteGenres,
    ProfileVisibility? visibility,
  }) async {
    try {
      // Build partial update body.
      // Only include fields the user actually changed (non-null).
      // Sending null fields could accidentally clear data on the server.
      final body = <String, dynamic>{};
      if (displayName != null) body['display_name'] = displayName;
      if (bio != null) body['bio'] = bio;
      if (location != null) body['location'] = location;
      if (favoriteGenres != null) body['favorite_genres'] = favoriteGenres;
      if (visibility != null) {
        // Convert enum back to the string the API expects
        body['visibility'] =
            visibility == ProfileVisibility.PUBLIC ? 'PUBLIC' : 'PRIVATE';
      }

      final dto = await _remoteDataSource.updateProfile(body);
      return dto.toEntity();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  }) async {
    try {
      return await _remoteDataSource.uploadProfileImage(
        imageType: imageType,
        filePath: filePath,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<bool> checkHandleAvailable(String handle) async {
    try {
      return await _remoteDataSource.checkHandleAvailable(handle);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Converts a DioException into a typed Failure.
  ///
  /// Matches the API doc error codes:
  /// 400 VALIDATION_FAILED → ValidationFailure
  /// 401 NOT_AUTHENTICATED → AuthFailure
  /// 403 FORBIDDEN         → ForbiddenFailure
  /// 404 NOT_FOUND         → NotFoundFailure
  /// anything else         → ServerFailure
  ///
  /// The [message] field comes from the API's global error format:
  /// { "statusCode": 400, "error": "VALIDATION_FAILED", "message": "..." }
  Failure _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] as String?;

    switch (statusCode) {
      case 400:
        return ValidationFailure(
          message ?? 'Please check your inputs.',
        );
      case 401:
        return AuthFailure('Session expired. Please log in again.');
      case 403:
        return ForbiddenFailure(
          'You do not have permission to view this profile.',
        );
      case 404:
        return NotFoundFailure('This profile does not exist.');
      default:
        return ServerFailure(
          message ?? 'Something went wrong. Please try again.',
        );
    }
  }
}
