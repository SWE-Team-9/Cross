import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notifications_result.dart';
import 'package:soundcloud_clone/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/notification_preferences_use_cases.dart';

class MockNotificationsRepository extends Mock implements NotificationsRepository {}

void main() {
  late MockNotificationsRepository repo;
  late GetNotificationPreferencesUseCase getPrefs;
  late UpdateNotificationPreferencesUseCase updatePrefs;

  setUp(() {
    repo = MockNotificationsRepository();
    getPrefs = GetNotificationPreferencesUseCase(repo);
    updatePrefs = UpdateNotificationPreferencesUseCase(repo);
  });

  test('get preferences returns success', () async {
    final prefs = NotificationPreferencesEntity.defaults();
    when(() => repo.getPreferences())
        .thenAnswer((_) async => NotificationsResult.success(prefs));

    final res = await getPrefs.call();
    expect(res, isA<NotificationsSuccess<NotificationPreferencesEntity>>());
  });

  test('update preferences returns failure when repository fails', () async {
    final prefs = NotificationPreferencesEntity.defaults();
    when(() => repo.updatePreferences(prefs)).thenAnswer(
      (_) async => const NotificationsResult.failure(ServerFailure('x')),
    );

    final res = await updatePrefs.call(prefs);
    expect(res, isA<NotificationsFailure>());
  });
}
