import 'package:dio/dio.dart';

import 'package:soundcloud_clone/features/social/domain/entities/user.dart';

class SocialRepo {
  final Dio dio;

  SocialRepo(this.dio);

  Future<List<User>> getFollowers(String userId, int page) async {
    try {
      final response = await dio.get(
        '/api/v1/social/$userId/followers',
        queryParameters: {'page': page},
      );

      return _parseUsersList(
        response.data,
        possibleKeys: const ['followers', 'data', 'items', 'results', 'users'],
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const <User>[];
      }
      rethrow;
    }
  }

  Future<List<User>> getFollowing(String userId, int page) async {
    try {
      final response = await dio.get(
        '/api/v1/social/$userId/following',
        queryParameters: {'page': page},
      );

      return _parseUsersList(
        response.data,
        possibleKeys: const ['following', 'data', 'items', 'results', 'users'],
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const <User>[];
      }
      rethrow;
    }
  }

  Future<bool> followUser(String userId) async {
    await dio.post('/api/v1/social/follow/$userId');
    return true;
  }

  Future<bool> unfollowUser(String userId) async {
    await dio.delete('/api/v1/social/follow/$userId');
    return true;
  }

  Future<bool> blockUser(String userId) async {
    await dio.post('/api/v1/social/block/$userId');
    return true;
  }

  Future<bool> unblockUser(String userId) async {
    await dio.delete('/api/v1/social/block/$userId');
    return true;
  }

  Future<String> getUserIdByHandle(String handle) async {
    final response = await dio.get('/api/v1/profiles/$handle');

    final Map<String, dynamic> data = _asMap(response.data);

    final dynamic idValue =
        data['id'] ?? data['_id'] ?? data['userId'] ?? data['user_id'];

    if (idValue is String && idValue.isNotEmpty) {
      return idValue;
    }

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
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw StateError('Expected a JSON object but got ${value.runtimeType}');
  }
}
