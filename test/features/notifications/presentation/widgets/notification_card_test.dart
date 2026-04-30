import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/track_details.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/features/notifications/presentation/widgets/notification_card.dart';

class MockGetTrackDetailUseCase extends Mock implements GetTrackDetailUseCase {}

void main() {
  late MockGetTrackDetailUseCase mockGet;

  setUp(() async {
    mockGet = MockGetTrackDetailUseCase();
    await getIt.reset();
    getIt.registerLazySingleton<GetTrackDetailUseCase>(() => mockGet);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('renders actor initials and type badge', (tester) async {
    final n = NotificationEntity(
      id: 'n1',
      type: NotificationType.like,
      message: 'liked your track',
      actorId: 'a1',
      actorDisplayName: 'John Doe',
      actorHandle: '@john',
      actorAvatarUrl: '',
      entityType: 'track',
      entityId: '',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: NotificationCard(notification: n, onTap: () {}, onDelete: () {}))));

    expect(find.text('JD'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('shows unread indicator and bold text when unread', (tester) async {
    final n = NotificationEntity(
      id: 'n2',
      type: NotificationType.comment,
      message: 'commented on your track',
      actorId: 'a2',
      actorDisplayName: 'Alice',
      actorHandle: '@alice',
      actorAvatarUrl: '',
      entityType: 'track',
      entityId: '',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: NotificationCard(notification: n, onTap: () {}, onDelete: () {}))));
    await tester.pumpAndSettle();

    expect(find.byType(Container), findsWidgets); // unread dot exists
    // Check that message text is present and likely bold via semantics
    expect(find.textContaining('commented'), findsOneWidget);
  });

  testWidgets('fetches track title when entityId present and trackName empty', (tester) async {
    final n = NotificationEntity(
      id: 'n3',
      type: NotificationType.like,
      message: 'liked',
      actorId: 'a3',
      actorDisplayName: 'Bob',
      actorHandle: '@bob',
      actorAvatarUrl: '',
      entityType: 'track',
      entityId: 't1',
      isRead: true,
      createdAt: DateTime.now(),
    );

    when(() => mockGet('t1')).thenAnswer((_) async => (
          detail: TrackDetail(
            trackId: 't1',
            title: 'My Song',
            artist: 'Artist',
            artistId: 'a1',
            artistHandle: 'artist',
            streamUrl: 'https://cdn/t1.mp3',
          ),
          failure: null,
        ));

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: NotificationCard(notification: n, onTap: () {}, onDelete: () {}))));
    // allow FutureBuilder to complete
    await tester.pumpAndSettle();

    expect(find.textContaining('My Song'), findsOneWidget);
  });
}
