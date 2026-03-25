import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';

void main() {
  test('profileByHandlePath builds expected path', () {
    expect(
      ApiConstants.profileByHandlePath('ali'),
      '/api/v1/profiles/ali',
    );
  });

  test('followersPath builds expected path', () {
    expect(
      ApiConstants.followersPath('u1'),
      '/api/v1/social/u1/followers',
    );
  });

  test('followingPath builds expected path', () {
    expect(
      ApiConstants.followingPath('u1'),
      '/api/v1/social/u1/following',
    );
  });

  test('followUserPath builds expected path', () {
    expect(
      ApiConstants.followUserPath('u1'),
      '/api/v1/social/follow/u1',
    );
  });

  test('blockUserPath builds expected path', () {
    expect(
      ApiConstants.blockUserPath('u1'),
      '/api/v1/social/block/u1',
    );
  });
}