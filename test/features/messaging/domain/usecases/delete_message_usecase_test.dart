import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/delete_message_usecase.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository repository;
  late DeleteMessageUseCase useCase;

  setUp(() {
    repository = MockMessagingRepository();
    useCase = DeleteMessageUseCase(repository);
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
}
