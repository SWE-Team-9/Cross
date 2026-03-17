import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';

void main() {
  group('User', () {
    test('creates instance with all fields', () {
      final date = DateTime(2000, 5, 15);

      const id = '1';
      const email = 'test@example.com';
      const username = 'muslim';
      const displayName = 'Muslim';
      const avatarUrl = 'https://example.com/avatar.png';
      const bio = 'Hello world';
      const gender = 'Male';

      final user = User(
        id: id,
        email: email,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        gender: gender,
        dateOfBirth: date,
        isPro: true,
        isProfileCompleted: true,
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
      expect(user.isProfileCompleted, true);
    });

    test('uses default values for isPro and isProfileCompleted', () {
      final user = User(
        id: '2',
        email: 'user2@example.com',
      );

      expect(user.id, '2');
      expect(user.email, 'user2@example.com');
      expect(user.username, isNull);
      expect(user.displayName, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.bio, isNull);
      expect(user.gender, isNull);
      expect(user.dateOfBirth, isNull);
      expect(user.isPro, false);
      expect(user.isProfileCompleted, false);
    });
  });
}