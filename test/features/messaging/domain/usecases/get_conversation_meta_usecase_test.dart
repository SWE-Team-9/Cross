import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversation_meta_usecase.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository repository;
  late GetConversationMetaUseCase useCase;

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
    useCase = GetConversationMetaUseCase(repository);
  });

  test('delegates to repository', () async {
    when(
      () => repository.getConversationMeta(any()),
    ).thenAnswer((_) async => result);

    final actual = await useCase('conversation-1');

    expect(actual, result);
    verify(
      () => repository.getConversationMeta('conversation-1'),
    ).called(1);
  });

  test('propagates repository errors', () async {
    final exception = Exception('failed');

    when(
      () => repository.getConversationMeta(any()),
    ).thenThrow(exception);

    expect(
      () => useCase('conversation-1'),
      throwsA(same(exception)),
    );
  });
}
