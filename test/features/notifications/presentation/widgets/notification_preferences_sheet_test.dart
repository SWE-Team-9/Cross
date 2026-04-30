import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notification_preferences_bloc.dart';
import 'package:soundcloud_clone/features/notifications/presentation/widgets/notification_preferences_sheet.dart';

class MockNotificationPreferencesBloc
    extends MockBloc<NotificationPreferencesEvent, NotificationPreferencesState>
    implements NotificationPreferencesBloc {}

class _FakeNotificationPreferencesEvent extends Fake implements NotificationPreferencesEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeNotificationPreferencesEvent());
  });

  late MockNotificationPreferencesBloc mockBloc;

  setUp(() {
    mockBloc = MockNotificationPreferencesBloc();
    when(() => mockBloc.stream).thenAnswer((_) => const Stream<NotificationPreferencesState>.empty());
  });

  testWidgets('shows loading indicator when loading', (tester) async {
    when(() => mockBloc.state).thenReturn(
      NotificationPreferencesState.initial().copyWith(isLoading: true, isSaving: false),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotificationPreferencesBloc>.value(
          value: mockBloc,
          child: const Scaffold(body: NotificationPreferencesSheet()),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders switches and toggles dispatch events', (tester) async {
    final prefs = NotificationPreferencesEntity.defaults().copyWith(likesEnabled: true, commentsEnabled: false);
    when(() => mockBloc.state).thenReturn(
      NotificationPreferencesState.initial().copyWith(isLoading: false, preferences: prefs),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotificationPreferencesBloc>.value(
          value: mockBloc,
          child: const Scaffold(body: NotificationPreferencesSheet()),
        ),
      ),
    );

    expect(find.text('Notification Preferences'), findsOneWidget);
    expect(find.text('Likes'), findsOneWidget);
    expect(find.text('Comments'), findsOneWidget);

    // Toggle the Comments switch (was false)
    await tester.tap(find.widgetWithText(SwitchListTile, 'Comments'));
    await tester.pumpAndSettle();

    verify(() => mockBloc.add(any(that: isA<TogglePreference>()))).called(1);
  });
}
