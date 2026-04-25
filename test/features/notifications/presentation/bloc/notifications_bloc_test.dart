import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:soundcloud_clone/features/notifications/domain/result/notifications_result.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/delete_notification_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/get_notifications_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/get_unread_count_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockGetNotificationsUseCase extends Mock
    implements GetNotificationsUseCase {}

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockMarkNotificationAsReadUseCase extends Mock
    implements MarkNotificationAsReadUseCase {}

class MockMarkAllNotificationsAsReadUseCase extends Mock
    implements MarkAllNotificationsAsReadUseCase {}

class MockDeleteNotificationUseCase extends Mock
    implements DeleteNotificationUseCase {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

NotificationEntity _makeNotification({
  String id = 'not_1',
  bool isRead = false,
}) =>
    NotificationEntity(
      id: id,
      type: NotificationType.like,
      message: 'Ali liked your track',
      actorId: 'usr_1',
      entityType: 'track',
      entityId: 'trk_1',
      isRead: isRead,
      createdAt: DateTime(2026, 3, 7),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late NotificationsBloc bloc;
  late MockGetNotificationsUseCase mockGetNotifications;
  late MockGetUnreadCountUseCase mockGetUnreadCount;
  late MockMarkNotificationAsReadUseCase mockMarkAsRead;
  late MockMarkAllNotificationsAsReadUseCase mockMarkAllAsRead;
  late MockDeleteNotificationUseCase mockDelete;
  late MockNotificationsRepository mockRepository;

  setUp(() {
    mockGetNotifications = MockGetNotificationsUseCase();
    mockGetUnreadCount = MockGetUnreadCountUseCase();
    mockMarkAsRead = MockMarkNotificationAsReadUseCase();
    mockMarkAllAsRead = MockMarkAllNotificationsAsReadUseCase();
    mockDelete = MockDeleteNotificationUseCase();
    mockRepository = MockNotificationsRepository();

    when(() => mockRepository.notificationStream)
        .thenAnswer((_) => const Stream.empty());

    bloc = NotificationsBloc(
      getNotifications: mockGetNotifications,
      getUnreadCount: mockGetUnreadCount,
      markAsRead: mockMarkAsRead,
      markAllAsRead: mockMarkAllAsRead,
      delete: mockDelete,
      repository: mockRepository,
    );
  });

  tearDown(() => bloc.close());

  // ── LoadNotifications ──────────────────────────────────────────────────────

  group('LoadNotifications', () {
    final tNotification = _makeNotification();

    blocTest<NotificationsBloc, NotificationsState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => mockGetNotifications(page: 1, limit: 20)).thenAnswer(
          (_) async => NotificationsResult.success([tNotification]),
        );
        when(() => mockGetUnreadCount()).thenAnswer(
          (_) async => const NotificationsResult.success(1),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadNotifications()),
      expect: () => [
        const NotificationsLoading(),
        isA<NotificationsLoaded>()
            .having((s) => s.notifications, 'notifications', [tNotification])
            .having((s) => s.unreadCount, 'unreadCount', 1),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockGetNotifications(page: 1, limit: 20)).thenAnswer(
          (_) async =>
              NotificationsResult.failure(ServerFailure('Server error')),
        );
        when(() => mockGetUnreadCount()).thenAnswer(
          (_) async => const NotificationsResult.success(0),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadNotifications()),
      expect: () => [
        const NotificationsLoading(),
        const NotificationsError('Server error'),
      ],
    );
  });

  // ── MarkNotificationRead ───────────────────────────────────────────────────

  group('MarkNotificationRead', () {
    final tNotification = _makeNotification(isRead: false);

    blocTest<NotificationsBloc, NotificationsState>(
      'optimistically marks notification as read and decrements unread count',
      build: () {
        when(() => mockMarkAsRead('not_1')).thenAnswer(
          (_) async => const NotificationsResult.success(null),
        );
        return bloc;
      },
      seed: () => NotificationsLoaded(
        notifications: [tNotification],
        unreadCount: 1,
      ),
      act: (b) => b.add(const MarkNotificationRead('not_1')),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.first.isRead, 'isRead', true)
            .having((s) => s.unreadCount, 'unreadCount', 0),
      ],
    );
  });

  // ── MarkAllNotificationsRead ───────────────────────────────────────────────

  group('MarkAllNotificationsRead', () {
    final tNotifications = [
      _makeNotification(id: 'not_1', isRead: false),
      _makeNotification(id: 'not_2', isRead: false),
    ];

    blocTest<NotificationsBloc, NotificationsState>(
      'marks all as read and sets unreadCount to 0',
      build: () {
        when(() => mockMarkAllAsRead()).thenAnswer(
          (_) async => const NotificationsResult.success(null),
        );
        return bloc;
      },
      seed: () => NotificationsLoaded(
        notifications: tNotifications,
        unreadCount: 2,
      ),
      act: (b) => b.add(const MarkAllNotificationsRead()),
      expect: () => [
        isA<NotificationsLoaded>()
            .having(
              (s) => s.notifications.every((n) => n.isRead),
              'all read',
              true,
            )
            .having((s) => s.unreadCount, 'unreadCount', 0),
      ],
    );
  });

  // ── DeleteNotification ─────────────────────────────────────────────────────

  group('DeleteNotification', () {
    final tNotification = _makeNotification();

    blocTest<NotificationsBloc, NotificationsState>(
      'removes notification from list',
      build: () {
        when(() => mockDelete('not_1')).thenAnswer(
          (_) async => const NotificationsResult.success(null),
        );
        return bloc;
      },
      seed: () => NotificationsLoaded(
        notifications: [tNotification],
        unreadCount: 0,
      ),
      act: (b) => b.add(const DeleteNotification('not_1')),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.notifications, 'notifications', isEmpty),
      ],
    );
  });

  // ── RealtimeNotificationReceived ───────────────────────────────────────────

  group('RealtimeNotificationReceived', () {
    final tExisting = _makeNotification(id: 'not_1');
    final tNew = _makeNotification(id: 'not_realtime');

    blocTest<NotificationsBloc, NotificationsState>(
      'prepends new notification and increments unread count',
      build: () => bloc,
      seed: () => NotificationsLoaded(
        notifications: [tExisting],
        unreadCount: 0,
      ),
      act: (b) => b.add(RealtimeNotificationReceived(tNew)),
      expect: () => [
        isA<NotificationsLoaded>()
            .having(
              (s) => s.notifications.first.id,
              'first notification is new',
              'not_realtime',
            )
            .having((s) => s.unreadCount, 'unreadCount', 1),
      ],
    );
  });
}