import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/presentation/widgets/notification_badge.dart';

class MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

void main() {
  late MockNotificationsBloc mockBloc;

  setUp(() {
    mockBloc = MockNotificationsBloc();
    when(() => mockBloc.stream)
        .thenAnswer((_) => Stream<NotificationsState>.empty());
    when(() => mockBloc.state).thenReturn(NotificationsLoaded(
        notifications: <NotificationEntity>[], unreadCount: 0));
  });

  testWidgets('renders child without badge when no provider', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationBadge(child: const Icon(Icons.notifications)),
        ),
      ),
    );

    expect(find.byIcon(Icons.notifications), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('shows badge when unread count > 0', (tester) async {
    when(() => mockBloc.state).thenReturn(NotificationsLoaded(
        notifications: <NotificationEntity>[], unreadCount: 5));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<NotificationsBloc>.value(
            value: mockBloc,
            child: NotificationBadge(child: const Icon(Icons.notifications)),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('shows 99+ when unread count > 99', (tester) async {
    when(() => mockBloc.state).thenReturn(NotificationsLoaded(
        notifications: <NotificationEntity>[], unreadCount: 150));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<NotificationsBloc>.value(
            value: mockBloc,
            child: NotificationBadge(child: const Icon(Icons.notifications)),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('99+'), findsOneWidget);
  });
}
