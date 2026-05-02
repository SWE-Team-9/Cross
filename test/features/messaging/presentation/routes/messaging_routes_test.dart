import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/presentation/routes/messaging_routes.dart';

void main() {
  group('MessagingRoutes', () {
    const participant = ParticipantEntity(
      id: 'user-1',
      displayName: 'Listener One',
      handle: 'listener',
      avatarUrl: null,
    );

    const conversation = ConversationEntity(
      conversationId: 'conversation-1',
      participant: participant,
      lastMessage: null,
      unreadCount: 0,
    );

    test('route constants are correct', () {
      expect(MessagingRoutes.inbox, '/messages');
      expect(MessagingRoutes.chatThread, '/messages/:conversationId');
    });

    testWidgets('goToInbox navigates to inbox path', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => MessagingRoutes.goToInbox(context),
                child: const Text('Go inbox'),
              ),
            ),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const Scaffold(
              body: Text('Inbox route'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('Go inbox'));
      await tester.pumpAndSettle();

      expect(find.text('Inbox route'), findsOneWidget);
    });

    testWidgets('goToConversation navigates using conversation id',
        (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => MessagingRoutes.goToConversation(
                  context,
                  conversation,
                ),
                child: const Text('Go conversation'),
              ),
            ),
          ),
          GoRoute(
            path: '/messages/:conversationId',
            builder: (context, state) => Scaffold(
              body: Text(
                state.pathParameters['conversationId'] ?? '',
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('Go conversation'));
      await tester.pumpAndSettle();

      expect(find.text('conversation-1'), findsOneWidget);
    });

    testWidgets('goToConversationById navigates using id', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => MessagingRoutes.goToConversationById(
                  context,
                  'conversation-2',
                ),
                child: const Text('Go by id'),
              ),
            ),
          ),
          GoRoute(
            path: '/messages/:conversationId',
            builder: (context, state) => Scaffold(
              body: Text(
                state.pathParameters['conversationId'] ?? '',
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('Go by id'));
      await tester.pumpAndSettle();

      expect(find.text('conversation-2'), findsOneWidget);
    });
  });
}
