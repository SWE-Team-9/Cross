import 'package:dio/dio.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';

class SocialRepo {
  final Dio dio;

  SocialRepo(this.dio);

  // ── Followers / Following ───────────────────────────────
  Future<List<User>> getFollowers(String userId, int page) async {
    final response = await dio.get(
      '${ApiConstants.socialBase}/$userId/followers',
      queryParameters: {'page': page},
    );

    final data = response.data as List;
    return data.map((e) => User.fromJson(e)).toList();
  }

  Future<List<User>> getFollowing(String userId, int page) async {
    final response = await dio.get(
      '${ApiConstants.socialBase}/$userId/following',
      queryParameters: {'page': page},
    );

    final data = response.data as List;
    return data.map((e) => User.fromJson(e)).toList();
  }

  //  Follow / Unfollow
  Future<bool> followUser(String userId) async {
    await dio.post('${ApiConstants.socialBase}/follow/$userId');
    return true;
  }

  Future<bool> unfollowUser(String userId) async {
    await dio.delete('${ApiConstants.socialBase}/follow/$userId');
    return true;
  }

  // Block / Unblock
  Future<bool> blockUser(String userId) async {
    await dio.post('${ApiConstants.socialBase}/block/$userId');
    return true;
  }

  Future<bool> unblockUser(String userId) async {
    await dio.delete('${ApiConstants.socialBase}/block/$userId');
    return true;
  }

  // Handle → userId
  Future<String> getUserIdByHandle(String handle) async {
    final response = await dio.get(
      '${ApiConstants.profileByHandle}/check-handle',
      queryParameters: {'handle': handle},
    );

    final data = response.data;
    return data['userId'] as String;
  }
}
