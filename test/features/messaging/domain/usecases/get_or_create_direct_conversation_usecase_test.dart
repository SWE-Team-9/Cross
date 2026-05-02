import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository repository;
  late GetOrCreateDirectConversationUseCase useCase;

  const participant = ParticipantEntity(
    id: 'user-1',
    displayName: 'Listener One',
    handle: '@listener',
    avatarUrl: null,
  );

  const result = ConversationEntity(
    conversationId: 'conversation-1',
    participant: participant,
    lastMessage: null,
    unreadCount: 0,
  );

  setUp(() {
    repository = MockMessagingRepository();
    useCase = GetOrCreateDirectConversationUseCase(repository);
  });

  test('delegates receiverId to repository', () async {
    when(
      () => repository.getOrCreateDirectConversation(
        receiverId: any(named: 'receiverId'),
      ),
    ).thenAnswer((_) async => result);

    final actual = await useCase(receiverId: 'receiver-1');

    expect(actual, result);
    verify(
      () => repository.getOrCreateDirectConversation(
        receiverId: 'receiver-1',
      ),
    ).called(1);
  });

  test('propagates repository errors', () async {
    final exception = Exception('failed');

    when(
      () => repository.getOrCreateDirectConversation(
        receiverId: any(named: 'receiverId'),
      ),
    ).thenThrow(exception);

    expect(
      () => useCase(receiverId: 'receiver-1'),
      throwsA(same(exception)),
    );
  });
}
