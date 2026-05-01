import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
// import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notification_preferences_bloc.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:soundcloud_clone/features/notifications/presentation/pages/notifications_page.dart';

class MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

class MockNotificationPreferencesBloc
    extends MockBloc<NotificationPreferencesEvent, NotificationPreferencesState>
    implements NotificationPreferencesBloc {}

void main() {
  late MockNotificationsBloc mockNotificationsBloc;
  late MockNotificationPreferencesBloc mockPrefsBloc;

  setUp(() {
    mockNotificationsBloc = MockNotificationsBloc();
    mockPrefsBloc = MockNotificationPreferencesBloc();

    when(() => mockNotificationsBloc.stream)
        .thenAnswer((_) => const Stream<NotificationsState>.empty());
    when(() => mockPrefsBloc.stream)
        .thenAnswer((_) => const Stream<NotificationPreferencesState>.empty());
  });

  testWidgets('shows empty view when no notifications', (tester) async {
    when(() => mockNotificationsBloc.state).thenReturn(
      NotificationsLoaded(
          notifications: <NotificationEntity>[], unreadCount: 0),
    );

    when(() => mockPrefsBloc.state).thenReturn(
      NotificationPreferencesState.initial(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<NotificationsBloc>.value(value: mockNotificationsBloc),
            BlocProvider<NotificationPreferencesBloc>.value(
                value: mockPrefsBloc),
          ],
          child: const NotificationsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('shows list and Mark all read when unread', (tester) async {
    final notification = NotificationEntity(
      id: '1',
      type: NotificationType.like,
      message: 'User liked your track',
      actorId: 'actor1',
      entityType: 'track',
      entityId: 'track1',
      isRead: false,
      createdAt: DateTime.now(),
    );

    when(() => mockNotificationsBloc.state).thenReturn(
      NotificationsLoaded(
          notifications: <NotificationEntity>[notification], unreadCount: 1),
    );

    when(() => mockPrefsBloc.state).thenReturn(
      NotificationPreferencesState.initial(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<NotificationsBloc>.value(value: mockNotificationsBloc),
            BlocProvider<NotificationPreferencesBloc>.value(
                value: mockPrefsBloc),
          ],
          child: const NotificationsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mark all read'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });
}
