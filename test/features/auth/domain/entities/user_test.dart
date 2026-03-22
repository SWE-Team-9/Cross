import 'package:flutter_test/flutter_test.dart';

// Third-party
// Project
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';

void main() {
  group('User Entity', () {
    test('creates instance with all fields', () {
      final date = DateTime(2000, 5, 15);

      const id = '1';
      const email = 'test@example.com';
      const username = 'muslim';
      const displayName = 'Muslim';
      const avatarUrl = 'https://example.com/avatar.png';
      const bio = 'Hello world';
      const gender = 'MALE';

      final user = User(
        id: id,
        email: email,
        handle: handle,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        gender: gender,
        dateOfBirth: date,
        isPro: true,
        isVerified: true, // تم التعديل من isProfileCompleted إلى isVerified
      );

      expect(user.id, id);
      expect(user.email, email);
      expect(user.username, username);
      expect(user.displayName, displayName);
      expect(user.avatarUrl, avatarUrl);
      expect(user.bio, bio);
      expect(user.gender, gender);
      expect(user.dateOfBirth, date);
      expect(user.isPro, true);
      expect(user.isVerified, true); // التعديل هنا أيضاً
    });

    test('uses default values for isPro and isVerified', () {
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
