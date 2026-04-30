import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_model.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_preferences_model.dart';
import 'package:soundcloud_clone/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notifications_result.dart';

class MockNotificationsRemoteDataSource extends Mock
		implements NotificationsRemoteDataSource {}

NotificationModel _model() {
	return NotificationModel(
		id: 'not_1',
		type: NotificationType.like,
		message: 'Ali liked your track Song2',
		actorId: 'usr_1',
		actorDisplayName: 'Ali',
		actorHandle: 'ali',
		actorAvatarUrl: '',
		entityType: 'track',
		entityId: 'trk_1',
		trackName: 'Song2',
		isRead: false,
		createdAt: DateTime.parse('2026-03-07T10:20:00Z'),
	);
}

void main() {
	late MockNotificationsRemoteDataSource remote;
	late NotificationsRepositoryImpl repository;

	setUpAll(() {
		registerFallbackValue(
			const NotificationPreferencesModel(
				likesEnabled: true,
				commentsEnabled: true,
				followsEnabled: true,
				repostsEnabled: true,
			),
		);
	});

	setUp(() {
		remote = MockNotificationsRemoteDataSource();
		repository = NotificationsRepositoryImpl(remote);
	});

	group('getNotifications', () {
		test('returns success when remote succeeds', () async {
			when(
				() => remote.getNotifications(
					page: 1,
					limit: 20,
					type: 'likes',
					isRead: false,
				),
			).thenAnswer((_) async => [_model()]);

			final result = await repository.getNotifications(
				page: 1,
				limit: 20,
				type: 'likes',
				isRead: false,
			);

			expect(result, isA<NotificationsSuccess<List<NotificationEntity>>>());
			verify(
				() => remote.getNotifications(
					page: 1,
					limit: 20,
					type: 'likes',
					isRead: false,
				),
			).called(1);
		});

		test('returns Failure result when remote throws Failure', () async {
			when(
				() => remote.getNotifications(
					page: 1,
					limit: 20,
					type: null,
					isRead: null,
				),
			).thenThrow(const NetworkFailure('offline'));

			final result = await repository.getNotifications();

			expect(result, isA<NotificationsFailure<List<NotificationEntity>>>());
		});
	});

	test('getUnreadCount maps generic exception to ServerFailure', () async {
		when(() => remote.getUnreadCount()).thenThrow(Exception('boom'));

		final result = await repository.getUnreadCount();

		expect(result, isA<NotificationsFailure<int>>());
		final failure = (result as NotificationsFailure<int>).failure;
		expect(failure, isA<ServerFailure>());
	});

	test('getUnreadCount maps Failure directly', () async {
		when(() => remote.getUnreadCount())
				.thenThrow(const NetworkFailure('offline'));

		final result = await repository.getUnreadCount();

		expect(result, isA<NotificationsFailure<int>>());
		expect((result as NotificationsFailure<int>).failure, isA<NetworkFailure>());
	});

	test('markAsRead returns success on happy path', () async {
		when(() => remote.markAsRead('not_1')).thenAnswer((_) async {});

		final result = await repository.markAsRead('not_1');

		expect(result, const NotificationsResult<void>.success(null));
	});

	test('markAsRead maps generic exception to ServerFailure', () async {
		when(() => remote.markAsRead('not_1')).thenThrow(Exception('boom'));

		final result = await repository.markAsRead('not_1');

		expect(result, isA<NotificationsFailure<void>>());
		expect((result as NotificationsFailure<void>).failure, isA<ServerFailure>());
	});

	test('markAllAsRead returns failure on remote failure', () async {
		when(() => remote.markAllAsRead()).thenThrow(const ServerFailure('x'));

		final result = await repository.markAllAsRead();

		expect(result, isA<NotificationsFailure<void>>());
	});

	test('markAllAsRead maps generic exception to ServerFailure', () async {
		when(() => remote.markAllAsRead()).thenThrow(Exception('boom'));

		final result = await repository.markAllAsRead();

		expect(result, isA<NotificationsFailure<void>>());
		expect((result as NotificationsFailure<void>).failure, isA<ServerFailure>());
	});

	test('deleteNotification forwards call', () async {
		when(() => remote.deleteNotification('not_1')).thenAnswer((_) async {});

		final result = await repository.deleteNotification('not_1');

		expect(result, const NotificationsResult<void>.success(null));
		verify(() => remote.deleteNotification('not_1')).called(1);
	});

	test('deleteNotification maps generic exception to ServerFailure', () async {
		when(() => remote.deleteNotification('not_1')).thenThrow(Exception('boom'));

		final result = await repository.deleteNotification('not_1');

		expect(result, isA<NotificationsFailure<void>>());
		expect((result as NotificationsFailure<void>).failure, isA<ServerFailure>());
	});

	test('getPreferences returns mapped model entity', () async {
		const prefs = NotificationPreferencesModel(
			likesEnabled: true,
			commentsEnabled: true,
			followsEnabled: false,
			repostsEnabled: true,
		);
		when(() => remote.getPreferences()).thenAnswer((_) async => prefs);

		final result = await repository.getPreferences();

		expect(result, isA<NotificationsSuccess<NotificationPreferencesEntity>>());
		expect(
			(result as NotificationsSuccess<NotificationPreferencesEntity>)
					.value
					.followsEnabled,
			false,
		);
	});

	test('getPreferences maps generic exception to ServerFailure', () async {
		when(() => remote.getPreferences()).thenThrow(Exception('boom'));

		final result = await repository.getPreferences();

		expect(result, isA<NotificationsFailure<NotificationPreferencesEntity>>());
		expect(
			(result as NotificationsFailure<NotificationPreferencesEntity>).failure,
			isA<ServerFailure>(),
		);
	});

	test('updatePreferences maps entity to model and calls remote', () async {
		when(
			() => remote.updatePreferences(any<NotificationPreferencesModel>()),
		).thenAnswer((_) async {});

		const prefs = NotificationPreferencesEntity(
			likesEnabled: true,
			commentsEnabled: false,
			followsEnabled: true,
			repostsEnabled: true,
		);

		final result = await repository.updatePreferences(prefs);

		expect(result, const NotificationsResult<void>.success(null));
		verify(
			() => remote.updatePreferences(
				const NotificationPreferencesModel(
					likesEnabled: true,
					commentsEnabled: false,
					followsEnabled: true,
					repostsEnabled: true,
				),
			),
		).called(1);
	});

	test('updatePreferences maps remote Failure', () async {
		when(
			() => remote.updatePreferences(any<NotificationPreferencesModel>()),
		).thenThrow(const ValidationFailure('invalid'));

		final result = await repository.updatePreferences(
			const NotificationPreferencesEntity(
				likesEnabled: true,
				commentsEnabled: true,
				followsEnabled: true,
				repostsEnabled: true,
			),
		);

		expect(result, isA<NotificationsFailure<void>>());
		expect((result as NotificationsFailure<void>).failure, isA<ValidationFailure>());
	});

	test('registerDevice and removeDevice call remote', () async {
		when(
			() => remote.registerDevice(deviceToken: 'token', platform: 'ios'),
		).thenAnswer((_) async {});
		when(() => remote.removeDevice('dev_1')).thenAnswer((_) async {});

		final registerResult =
				await repository.registerDevice(deviceToken: 'token', platform: 'ios');
		final removeResult = await repository.removeDevice('dev_1');

		expect(registerResult, const NotificationsResult<void>.success(null));
		expect(removeResult, const NotificationsResult<void>.success(null));
	});

	test('registerDevice maps generic exception to ServerFailure', () async {
		when(
			() => remote.registerDevice(deviceToken: 'token', platform: 'ios'),
		).thenThrow(Exception('boom'));

		final result =
				await repository.registerDevice(deviceToken: 'token', platform: 'ios');

		expect(result, isA<NotificationsFailure<void>>());
		expect((result as NotificationsFailure<void>).failure, isA<ServerFailure>());
	});

	test('removeDevice maps Failure directly', () async {
		when(() => remote.removeDevice('dev_1'))
				.thenThrow(const NetworkFailure('offline'));

		final result = await repository.removeDevice('dev_1');

		expect(result, isA<NotificationsFailure<void>>());
		expect((result as NotificationsFailure<void>).failure, isA<NetworkFailure>());
	});

	test('notificationStream proxies remote stream', () async {
		final stream = Stream<NotificationModel>.value(_model());
		when(() => remote.notificationStream).thenAnswer((_) => stream);

		expect(repository.notificationStream, emits(isA<NotificationEntity>()));
	});
}
