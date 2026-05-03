import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notification_preferences_bloc.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:soundcloud_clone/features/notifications/presentation/pages/notifications_page.dart';
import 'package:soundcloud_clone/features/notifications/presentation/widgets/notification_card.dart';

class MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

class MockNotificationPreferencesBloc
    extends MockBloc<NotificationPreferencesEvent, NotificationPreferencesState>
    implements NotificationPreferencesBloc {}

class _FakeNotificationsEvent extends Fake implements NotificationsEvent {}

class _FakeNotificationPreferencesEvent extends Fake
    implements NotificationPreferencesEvent {}

NotificationEntity makeNotification(
  String id, {
  NotificationType type = NotificationType.like,
  bool isRead = false,
}) {
  return NotificationEntity(
    id: id,
    type: type,
    message: '$id message',
    actorId: 'actor-$id',
    actorDisplayName: 'Actor $id',
    actorHandle: 'actor$id',
    entityType: 'track',
    entityId: 'entity-$id',
    trackName: 'Track $id',
    isRead: isRead,
    createdAt: DateTime.now(),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeNotificationsEvent());
    registerFallbackValue(_FakeNotificationPreferencesEvent());
  });

  late MockNotificationsBloc notificationsBloc;
  late MockNotificationPreferencesBloc preferencesBloc;

  setUp(() {
    notificationsBloc = MockNotificationsBloc();
    preferencesBloc = MockNotificationPreferencesBloc();

    when(() => notificationsBloc.stream)
        .thenAnswer((_) => const Stream<NotificationsState>.empty());
    when(() => preferencesBloc.stream).thenAnswer(
      (_) => const Stream<NotificationPreferencesState>.empty(),
    );
    when(() => notificationsBloc.state)
        .thenReturn(const NotificationsInitial());
    when(() => preferencesBloc.state)
        .thenReturn(NotificationPreferencesState.initial());
  });

  Widget buildPage() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<NotificationsBloc>.value(value: notificationsBloc),
          BlocProvider<NotificationPreferencesBloc>.value(
              value: preferencesBloc),
        ],
        child: const NotificationsPage(),
      ),
    );
  }

  testWidgets('shows loading indicator while loading', (tester) async {
    when(() => notificationsBloc.state)
        .thenReturn(const NotificationsLoading());

    await tester.pumpWidget(buildPage());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty view when no notifications', (tester) async {
    when(() => notificationsBloc.state).thenReturn(
      const NotificationsLoaded(notifications: [], unreadCount: 0),
    );

    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.text('Likes, comments, and follows will appear here.'),
        findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets('shows list and Mark all read when unread', (tester) async {
    final notifications = [
      makeNotification('like-1', type: NotificationType.like),
      makeNotification('comment-1', type: NotificationType.comment),
      makeNotification('follow-1', type: NotificationType.follow),
      makeNotification('repost-1', type: NotificationType.repost),
      makeNotification('message-1', type: NotificationType.message),
      makeNotification('unknown-1', type: NotificationType.unknown),
    ];

    when(() => notificationsBloc.state).thenReturn(
      NotificationsLoaded(
        notifications: notifications,
        unreadCount: notifications.length,
        hasMore: false,
        currentPage: 1,
      ),
    );

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.text('Mark all read'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(NotificationCard), findsNWidgets(notifications.length));
  });

  testWidgets('shows loading more spinner when appending results',
      (tester) async {
    when(() => notificationsBloc.state).thenReturn(
      NotificationsLoadingMore(
        notifications: [makeNotification('like-1')],
        unreadCount: 1,
        hasMore: true,
        currentPage: 1,
      ),
    );

    await tester.pumpWidget(buildPage());
    await tester.pump();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('dispatches load more when scrolled near the bottom',
      (tester) async {
    final notifications = List.generate(
      30,
      (index) => makeNotification('n$index'),
    );

    when(() => notificationsBloc.state).thenReturn(
      NotificationsLoaded(
        notifications: notifications,
        unreadCount: notifications.length,
        hasMore: true,
        currentPage: 1,
      ),
    );

    await tester.pumpWidget(buildPage());
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();

    verify(() => notificationsBloc.add(const LoadMoreNotifications()))
        .called(1);
  });

  testWidgets('shows error state when load fails', (tester) async {
    when(() => notificationsBloc.state).thenReturn(
      const NotificationsError('Failed to load notifications'),
    );

    await tester.pumpWidget(buildPage());

    expect(find.text('Failed to load notifications'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
