import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_messages_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversation_messages_usecase.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository repository;
  late GetConversationMessagesUseCase useCase;

  late ConversationMessagesPageEntity result;

  setUp(() {
    repository = MockMessagingRepository();
    useCase = GetConversationMessagesUseCase(repository);

    result = ConversationMessagesPageEntity(
      conversationId: 'conversation-1',
      page: 1,
      limit: 50,
      messages: <MessageEntity>[
        MessageEntity(
          id: 'message-1',
          conversationId: 'conversation-1',
          senderId: 'sender-1',
          receiverId: 'receiver-1',
          type: MessageType.text,
          text: 'Hello',
          isRead: false,
          createdAt: DateTime.utc(2026, 4, 30),
          sharedTrack: null,
          sharedPlaylist: null,
        ),
      ],
    );
  });

  test('calls repository with default pagination', () async {
    when(
      () => repository.getConversationMessages(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => result);

    final actual = await useCase('conversation-1');

    expect(actual, result);
    verify(
      () => repository.getConversationMessages(
        'conversation-1',
        page: 1,
        limit: 50,
      ),
    ).called(1);
  });

  test('passes custom pagination', () async {
    when(
      () => repository.getConversationMessages(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => result);

    await useCase('conversation-1', page: 2, limit: 25);

    verify(
      () => repository.getConversationMessages(
        'conversation-1',
        page: 2,
        limit: 25,
      ),
    ).called(1);
  });

  test('propagates repository errors', () async {
    final exception = Exception('failed');

    when(
      () => repository.getConversationMessages(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenThrow(exception);

    expect(
      () => useCase('conversation-1'),
      throwsA(same(exception)),
    );
  });
}
