import 'package:flutter_test/flutter_test.dart';

// Third-party
// Project
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';

void main() {
  group('User', () {
    User buildUser({
      String id = 'user-uuid-123',
      String email = 'ahmed@test.com',
      String handle = 'ahmed-hassan-beats',
      String? displayName = 'Ahmed Hassan',
      String? avatarUrl,
      String? bio,
      bool isPro = false,
      bool isProfileCompleted = false,
    }) {
      return User(
        id: id,
        email: email,
        handle: handle,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        isPro: isPro,
        isProfileCompleted: isProfileCompleted,
      );
    }

    test('creates User with all required fields correctly', () {
      final user = buildUser();

      expect(user.id, 'user-uuid-123');
      expect(user.email, 'ahmed@test.com');
      expect(user.handle, 'ahmed-hassan-beats');
      expect(user.isPro, isFalse);
      expect(user.isProfileCompleted, isFalse);
    });

    test('handle stores the provided value', () {
      final user = buildUser(handle: 'my-custom-handle');

      expect(user.handle, 'my-custom-handle');
    });

    test('optional fields default to null when not provided', () {
      final user = User(
        id: 'user-uuid-123',
        email: 'ahmed@test.com',
        handle: 'ahmed-hassan-beats',
      );

      expect(user.username, isNull);
      expect(user.displayName, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.bio, isNull);
      expect(user.gender, isNull);
      expect(user.dateOfBirth, isNull);
    });

    test('isPro defaults to false', () {
      final user = User(
        id: 'user-uuid-123',
        email: 'ahmed@test.com',
        handle: 'ahmed-hassan-beats',
      );

      expect(user.isPro, isFalse);
    });

    test('isProfileCompleted defaults to false', () {
      final user = User(
        id: 'user-uuid-123',
        email: 'ahmed@test.com',
        handle: 'ahmed-hassan-beats',
      );

      expect(user.isProfileCompleted, isFalse);
    });

    test('stores avatarUrl when provided', () {
      final user = buildUser(
        avatarUrl: 'https://s3.aws.com/ahmed-avatar.jpg',
      );

      expect(user.avatarUrl, 'https://s3.aws.com/ahmed-avatar.jpg');
    });
  });
}
