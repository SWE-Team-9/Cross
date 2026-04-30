import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_model.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_preferences_model.dart';

class MockDioClient extends Mock implements DioClient {}

Response<dynamic> responseWith(dynamic data) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/x'),
    data: data,
  );
}

void main() {
  late MockDioClient client;
  late NotificationsRemoteDataSourceImpl dataSource;

  setUp(() {
    client = MockDioClient();
    dataSource = NotificationsRemoteDataSourceImpl(client: client);
  });

  group('getNotifications', () {
    test('sends paging/filter params and parses notifications list', () async {
      when(
        () => client.get(
          '/api/v1/notifications',
          queryParameters: {
            'page': 2,
            'limit': 10,
            'type': 'likes',
            'isRead': false,
          },
        ),
      ).thenAnswer(
        (_) async => responseWith({
          'data': {
            'notifications': [
              {
                'id': 'not_1',
                'type': 'like',
                'message': 'Ali liked your track',
                'actorHandle': 'ali',
                'entityType': 'track',
                'entityId': 'trk_1',
                'target': {'title': 'Song2'},
                'isRead': false,
                'createdAt': '2026-03-07T10:20:00Z',
              }
            ]
          }
        }),
      );

      final result = await dataSource.getNotifications(
        page: 2,
        limit: 10,
        type: 'likes',
        isRead: false,
      );

      expect(result, hasLength(1));
      expect(result.first, isA<NotificationModel>());
      expect(result.first.trackName, 'Song2');
    });

    test('returns empty list when payload structure is unknown', () async {
      when(
        () => client.get('/api/v1/notifications', queryParameters: {'page': 1, 'limit': 20}),
      ).thenAnswer((_) async => responseWith({'data': {'foo': 'bar'}}));

      final result = await dataSource.getNotifications();

      expect(result, isEmpty);
    });
  });

  group('getUnreadCount', () {
    test('reads count from map payload', () async {
      when(() => client.get('/api/v1/notifications/unread-count'))
          .thenAnswer((_) async => responseWith({'data': {'count': 5}}));

      final result = await dataSource.getUnreadCount();

      expect(result, 5);
    });

    test('handles numeric payload directly', () async {
      when(() => client.get('/api/v1/notifications/unread-count'))
          .thenAnswer((_) async => responseWith(7));

      final result = await dataSource.getUnreadCount();

      expect(result, 7);
    });

    test('falls back to zero for invalid payload', () async {
      when(() => client.get('/api/v1/notifications/unread-count'))
          .thenAnswer((_) async => responseWith({'data': {'count': 'abc'}}));

      final result = await dataSource.getUnreadCount();

      expect(result, 0);
    });
  });

  test('markAsRead calls patch endpoint', () async {
    when(() => client.patch('/api/v1/notifications/not_1/read'))
        .thenAnswer((_) async => responseWith({}));

    await dataSource.markAsRead('not_1');

    verify(() => client.patch('/api/v1/notifications/not_1/read')).called(1);
  });

  test('markAllAsRead calls patch endpoint', () async {
    when(() => client.patch('/api/v1/notifications/read-all'))
        .thenAnswer((_) async => responseWith({}));

    await dataSource.markAllAsRead();

    verify(() => client.patch('/api/v1/notifications/read-all')).called(1);
  });

  test('deleteNotification calls delete endpoint', () async {
    when(() => client.delete('/api/v1/notifications/not_1'))
        .thenAnswer((_) async => responseWith({}));

    await dataSource.deleteNotification('not_1');

    verify(() => client.delete('/api/v1/notifications/not_1')).called(1);
  });

  group('preferences', () {
    test('getPreferences parses map payload', () async {
      when(() => client.get('/api/v1/notifications/preferences')).thenAnswer(
        (_) async => responseWith({
          'data': {
            'likes': true,
            'comments': false,
            'follows': true,
            'reposts': true,
          }
        }),
      );

      final result = await dataSource.getPreferences();

      expect(result.likesEnabled, true);
      expect(result.commentsEnabled, false);
      expect(result.followsEnabled, true);
      expect(result.repostsEnabled, true);
    });

    test('getPreferences returns defaults for invalid payload', () async {
      when(() => client.get('/api/v1/notifications/preferences'))
          .thenAnswer((_) async => responseWith('invalid'));

      final result = await dataSource.getPreferences();

      expect(result.likesEnabled, true);
      expect(result.commentsEnabled, true);
      expect(result.followsEnabled, true);
      expect(result.repostsEnabled, true);
    });

    test('updatePreferences sends mapped body', () async {
      when(
        () => client.put(
          '/api/v1/notifications/preferences',
          data: {
            'likes': true,
            'comments': false,
            'follows': true,
            'reposts': false,
          },
        ),
      ).thenAnswer((_) async => responseWith({}));

      await dataSource.updatePreferences(
        const NotificationPreferencesModel(
          likesEnabled: true,
          commentsEnabled: false,
          followsEnabled: true,
          repostsEnabled: false,
        ),
      );

      verify(
        () => client.put(
          '/api/v1/notifications/preferences',
          data: {
            'likes': true,
            'comments': false,
            'follows': true,
            'reposts': false,
          },
        ),
      ).called(1);
    });
  });

  test('registerDevice and removeDevice call expected endpoints', () async {
    when(
      () => client.post(
        '/api/v1/notifications/push/register',
        data: {'deviceToken': 'abc123', 'platform': 'ios'},
      ),
    ).thenAnswer((_) async => responseWith({}));
    when(() => client.delete('/api/v1/notifications/push/dev_1'))
        .thenAnswer((_) async => responseWith({}));

    await dataSource.registerDevice(deviceToken: 'abc123', platform: 'ios');
    await dataSource.removeDevice('dev_1');

    verify(
      () => client.post(
        '/api/v1/notifications/push/register',
        data: {'deviceToken': 'abc123', 'platform': 'ios'},
      ),
    ).called(1);
    verify(() => client.delete('/api/v1/notifications/push/dev_1')).called(1);
  });

  test('notificationStream returns injected stream', () async {
    final stream = Stream<NotificationModel>.value(
      NotificationModel.fromJson({
        'id': 'not_9',
        'type': 'like',
        'message': 'x',
        'entityType': 'track',
        'entityId': 'trk',
      }),
    );
    final sut = NotificationsRemoteDataSourceImpl(
      client: client,
      notificationStream: stream,
    );

    expect(sut.notificationStream, emits(isA<NotificationModel>()));
  });
}
