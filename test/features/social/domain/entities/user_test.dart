import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';

void main() {
  group('Social User.fromJson', () {
    test('maps standard keys correctly', () {
      final user = User.fromJson({
        'id': '1',
        'username': 'ali',
        'isFollowing': true,
        'followersCount': 12,
      });

      expect(user.id, '1');
      expect(user.username, 'ali');
      expect(user.isFollowing, isTrue);
      expect(user.followersCount, 12);
    });

    test('maps fallback keys correctly', () {
      final user = User.fromJson({
        '_id': '2',
        'handle': 'ali-handle',
        'is_following': false,
        'followers_count': 7,
      });

      expect(user.id, '2');
      expect(user.username, 'ali-handle');
      expect(user.isFollowing, isFalse);
      expect(user.followersCount, 7);
    });

    test('maps display_name fallback', () {
      final user = User.fromJson({
        'userId': '3',
        'display_name': 'Ali Mahmoud',
      });

      expect(user.id, '3');
      expect(user.username, 'Ali Mahmoud');
      expect(user.isFollowing, isFalse);
      expect(user.followersCount, 0);
    });

    test('maps displayName fallback', () {
      final user = User.fromJson({
        'user_id': '4',
        'displayName': 'Ali Display',
      });

      expect(user.id, '4');
      expect(user.username, 'Ali Display');
    });

    test('parses string booleans and int strings', () {
      final user = User.fromJson({
        'id': '5',
        'username': 'ali',
        'isFollowing': 'true',
        'followersCount': '15',
      });

      expect(user.isFollowing, isTrue);
      expect(user.followersCount, 15);
    });

    test('uses defaults for missing values', () {
      final user = User.fromJson({});

      expect(user.id, '');
      expect(user.username, '');
      expect(user.isFollowing, isFalse);
      expect(user.followersCount, 0);
    });
  });

  group('Social User.toJson', () {
    test('serializes all fields', () {
      final user = User(
        id: '1',
        username: 'ali',
        isFollowing: true,
        followersCount: 9,
      );

      expect(user.toJson(), {
        'id': '1',
        'username': 'ali',
        'isFollowing': true,
        'followersCount': 9,
      });
    });
  });

  group('Social User.copyWith', () {
    test('updates provided fields only', () {
      final user = User(
        id: '1',
        username: 'ali',
        isFollowing: false,
        followersCount: 10,
      );

      final updated = user.copyWith(
        isFollowing: true,
        followersCount: 20,
      );

      expect(updated.id, '1');
      expect(updated.username, 'ali');
      expect(updated.isFollowing, isTrue);
      expect(updated.followersCount, 20);
    });

    test('keeps original values when no overrides are provided', () {
      final user = User(
        id: '1',
        username: 'ali',
        isFollowing: false,
        followersCount: 10,
      );

      final updated = user.copyWith();

      expect(updated.id, '1');
      expect(updated.username, 'ali');
      expect(updated.isFollowing, isFalse);
      expect(updated.followersCount, 10);
    });
  });
}