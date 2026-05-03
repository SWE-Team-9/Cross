import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/delete_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/delete_conversation_usecase.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository repository;
  late DeleteMessageUseCase useCase;
  late DeleteConversationUseCase deleteConversationUseCase;

  setUp(() {
    repository = MockMessagingRepository();
    useCase = DeleteMessageUseCase(repository);
    deleteConversationUseCase = DeleteConversationUseCase(repository);
  });

  test('delegates messageId to repository', () async {
    when(
      () => repository.deleteMessage(any()),
    ).thenAnswer((_) async {});

    await useCase('message-1');

    verify(
      () => repository.deleteMessage('message-1'),
    ).called(1);
  });

  test('propagates repository errors', () async {
    final exception = Exception('failed');

    when(
      () => repository.deleteMessage(any()),
    ).thenThrow(exception);

    expect(
      () => useCase('message-1'),
      throwsA(same(exception)),
    );
  });

  test('delegates conversationId to repository', () async {
    when(
      () => repository.deleteConversation(any()),
    ).thenAnswer((_) async {});

    await deleteConversationUseCase('conversation-1');

    verify(
      () => repository.deleteConversation('conversation-1'),
    ).called(1);
  });

  test('conversation usecase propagates repository errors', () async {
    final exception = Exception('failed');

    when(
      () => repository.deleteConversation(any()),
    ).thenThrow(exception);

    expect(
      () => deleteConversationUseCase('conversation-1'),
      throwsA(same(exception)),
    );
  });
}
