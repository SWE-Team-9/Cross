import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notifications_result.dart';
import 'package:soundcloud_clone/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/get_notifications_use_case.dart';

class MockNotificationsRepository extends Mock
		implements NotificationsRepository {}

void main() {
	late MockNotificationsRepository repository;
	late GetNotificationsUseCase useCase;

	setUp(() {
		repository = MockNotificationsRepository();
		useCase = GetNotificationsUseCase(repository);
	});

	test('forwards paging/filter args and returns repository result', () async {
		const expected = NotificationsResult<List<NotificationEntity>>.success([]);

		when(
			() => repository.getNotifications(
				page: 2,
				limit: 50,
				type: 'likes',
				isRead: false,
			),
		).thenAnswer((_) async => expected);

		final result = await useCase(
			page: 2,
			limit: 50,
			type: 'likes',
			isRead: false,
		);

		expect(result, expected);
		verify(
			() => repository.getNotifications(
				page: 2,
				limit: 50,
				type: 'likes',
				isRead: false,
			),
		).called(1);
	});

	test('uses defaults when optional args are omitted', () async {
		const expected = NotificationsResult<List<NotificationEntity>>.success([]);

		when(
			() => repository.getNotifications(
				page: 1,
				limit: 20,
				type: null,
				isRead: null,
			),
		).thenAnswer((_) async => expected);

		final result = await useCase();

		expect(result, expected);
	});
}
