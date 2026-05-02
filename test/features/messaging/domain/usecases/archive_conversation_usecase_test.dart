import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/archive_conversation_usecase.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository repository;
  late ArchiveConversationUseCase useCase;

  setUp(() {
    repository = MockMessagingRepository();
    useCase = ArchiveConversationUseCase(repository);
  });

  test('delegates conversationId to repository', () async {
    when(
      () => repository.archiveConversation(any()),
    ).thenAnswer((_) async {});

    await useCase('conversation-1');

    verify(
      () => repository.archiveConversation('conversation-1'),
    ).called(1);
  });

  test('propagates repository errors', () async {
    final exception = Exception('failed');

    when(
      () => repository.archiveConversation(any()),
    ).thenThrow(exception);

    expect(
      () => useCase('conversation-1'),
      throwsA(same(exception)),
    );
  });
}
