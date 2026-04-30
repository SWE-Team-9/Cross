import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/features/notifications/data/models/notification_preferences_model.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';

void main() {
  test('fromJson reads backend keys', () {
    final model = NotificationPreferencesModel.fromJson({
      'likes': true,
      'comments': false,
      'follows': true,
      'reposts': false,
    });

    expect(model.likesEnabled, true);
    expect(model.commentsEnabled, false);
    expect(model.followsEnabled, true);
    expect(model.repostsEnabled, false);
  });

  test('fromJson supports enabled-style keys and defaults', () {
    final model = NotificationPreferencesModel.fromJson({
      'likesEnabled': false,
    });

    expect(model.likesEnabled, false);
    expect(model.commentsEnabled, true);
    expect(model.followsEnabled, true);
    expect(model.repostsEnabled, true);
  });

  test('fromEntity maps fields', () {
    const entity = NotificationPreferencesEntity(
      likesEnabled: false,
      commentsEnabled: true,
      followsEnabled: false,
      repostsEnabled: true,
    );

    final model = NotificationPreferencesModel.fromEntity(entity);

    expect(model.likesEnabled, false);
    expect(model.commentsEnabled, true);
    expect(model.followsEnabled, false);
    expect(model.repostsEnabled, true);
  });

  test('toJson writes backend contract keys', () {
    const model = NotificationPreferencesModel(
      likesEnabled: true,
      commentsEnabled: false,
      followsEnabled: true,
      repostsEnabled: false,
    );

    expect(
      model.toJson(),
      {
        'likes': true,
        'comments': false,
        'follows': true,
        'reposts': false,
      },
    );
  });
}
