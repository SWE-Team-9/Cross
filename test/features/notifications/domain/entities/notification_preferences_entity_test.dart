import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';

void main() {
  test('defaults enables all preferences', () {
    final entity = NotificationPreferencesEntity.defaults();

    expect(entity.likesEnabled, true);
    expect(entity.commentsEnabled, true);
    expect(entity.followsEnabled, true);
    expect(entity.repostsEnabled, true);
  });

  test('copyWith updates selected fields only', () {
    const entity = NotificationPreferencesEntity(
      likesEnabled: true,
      commentsEnabled: true,
      followsEnabled: false,
      repostsEnabled: false,
    );

    final copied =
        entity.copyWith(commentsEnabled: false, repostsEnabled: true);

    expect(copied.likesEnabled, true);
    expect(copied.commentsEnabled, false);
    expect(copied.followsEnabled, false);
    expect(copied.repostsEnabled, true);
  });

  test('equatable props match by value', () {
    const a = NotificationPreferencesEntity(
      likesEnabled: true,
      commentsEnabled: false,
      followsEnabled: true,
      repostsEnabled: false,
    );
    const b = NotificationPreferencesEntity(
      likesEnabled: true,
      commentsEnabled: false,
      followsEnabled: true,
      repostsEnabled: false,
    );

    expect(a, b);
  });
}
