import 'package:soundcloud_clone/features/social/domain/entities/user.dart';

class SocialRepo {
  final List<User> _users = [
    User(id: '1', username: 'Ahmed'),
    User(id: '2', username: 'Ali'),
    User(id: '3', username: 'Sara'),
  ];

  Future<List<User>> getFollowers(String userId, int page) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return _users;
  }

  Future<List<User>> getFollowing(String userId, int page) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return _users;
  }

  //  Follow/unFollow
  Future<bool> followUser(String userId) async {
    // TODO: backend later
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<bool> unfollowUser(String userId) async {
    // TODO: backend later
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  //Block/unBlock
  Future<bool> blockUser(String userId) async {
    // TODO: backend later
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<bool> unblockUser(String userId) async {
    // TODO: backend later
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
