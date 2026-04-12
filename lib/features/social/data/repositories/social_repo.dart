import 'package:dio/dio.dart';

import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import '../../../../core/network/api_constants.dart';

class SocialRepo {
  final Dio dio;

  SocialRepo(this.dio);

  Future<List<User>> getFollowers(
    String userId,
    int page, {
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.followersPath(userId),
        queryParameters: {'page': page, 'limit': limit},
      );

      return _parseUsersList(
        response.data,
        possibleKeys: const ['followers', 'data', 'items', 'results', 'users'],
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const <User>[];
      rethrow;
    }
  }

  Future<List<User>> getFollowing(
    String userId,
    int page, {
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.followingPath(userId),
        queryParameters: {'page': page, 'limit': limit},
      );

      return _parseUsersList(
        response.data,
        possibleKeys: const ['following', 'data', 'items', 'results', 'users'],
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const <User>[];
      rethrow;
    }
  }

  Future<List<User>> getBlockedUsers(
    int page, {
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.blockedUsersPath,
        queryParameters: {'page': page, 'limit': limit},
      );

      return _parseUsersList(
        response.data,
        possibleKeys: const [
          'blockedUsers',
          'blocked_users',
          'data',
          'items',
          'results',
          'users'
        ],
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const <User>[];
      rethrow;
    }
  }

  /// بيرجع [followersCount] و [isFollowing] الحقيقيين من الـ API
  Future<({bool isFollowing, int followersCount})> followUser(
      String userId) async {
    final response = await dio.post(ApiConstants.followUserPath(userId));
    final data = _asMap(response.data);
    return (
      isFollowing: (data['isFollowing'] ?? true) as bool,
      followersCount: (data['followersCount'] ?? 0) as int,
    );
  }

  /// بيرجع [isFollowing] الحقيقي من الـ API
  Future<({bool isFollowing, int? followersCount})> unfollowUser(
      String userId) async {
    final response = await dio.delete(ApiConstants.followUserPath(userId));
    final data = _asMap(response.data);
    return (
      isFollowing: (data['isFollowing'] ?? false) as bool,
      followersCount: data['followersCount'] as int?,
    );
  }

  /// بيرجع [blockedUserId] تأكيد من الـ API — POST /api/v1/social/block/{userId}
  Future<bool> blockUser(String userId) async {
    try {
      final response = await dio.post(ApiConstants.blockUserPath(userId));
      final data = _asMap(response.data);
      // الـ API بيرجع { "message": "...", "blockedUserId": "usr_999" }
      final blockedId = data['blockedUserId']?.toString() ?? '';
      return blockedId.isNotEmpty;
    } on DioException {
      return false;
    }
  }

  /// بيرجع [blockedUserId] تأكيد من الـ API — DELETE /api/v1/social/block/{userId}
  Future<bool> unblockUser(String userId) async {
    try {
      final response = await dio.delete(ApiConstants.blockUserPath(userId));
      final data = _asMap(response.data);
      // الـ API بيرجع { "message": "...", "blockedUserId": "usr_999" }
      final blockedId = data['blockedUserId']?.toString() ?? '';
      return blockedId.isNotEmpty;
    } on DioException {
      return false;
    }
  }

  Future<String> getUserIdByHandle(String handle) async {
    final response = await dio.get(ApiConstants.profileByHandlePath(handle));
    final Map<String, dynamic> data = _asMap(response.data);
    final dynamic idValue =
        data['id'] ?? data['_id'] ?? data['userId'] ?? data['user_id'];

    if (idValue is String && idValue.isNotEmpty) return idValue;

    throw StateError(
      'Profile response for handle "$handle" does not contain a user id.',
    );
  }

  List<User> _parseUsersList(
    dynamic raw, {
    required List<String> possibleKeys,
  }) {
    if (raw is List) {
      return raw.map((e) => User.fromJson(_asMap(e))).toList(growable: false);
    }

    if (raw is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        final value = raw[key];
        if (value is List) {
          return value
              .map((e) => User.fromJson(_asMap(e)))
              .toList(growable: false);
        }
      }
    }

    return const <User>[];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw StateError('Expected a JSON object but got ${value.runtimeType}');
  }
}
