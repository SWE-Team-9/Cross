import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/send_text_message_usecase.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository repository;
  late SendTextMessageUseCase useCase;

  late MessageEntity result;

  setUp(() {
    repository = MockMessagingRepository();
    useCase = SendTextMessageUseCase(repository);

    result = MessageEntity(
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
    );
  });

  test('delegates receiverId and text to repository', () async {
    when(
      () => repository.sendTextMessage(
        receiverId: any(named: 'receiverId'),
        text: any(named: 'text'),
      ),
    ).thenAnswer((_) async => result);

    final actual = await useCase(
      receiverId: 'receiver-1',
      text: 'Hello',
    );

    expect(actual, result);
    verify(
      () => repository.sendTextMessage(
        receiverId: 'receiver-1',
        text: 'Hello',
      ),
    ).called(1);
  });

  test('propagates repository errors', () async {
    final exception = Exception('failed');

    when(
      () => repository.sendTextMessage(
        receiverId: any(named: 'receiverId'),
        text: any(named: 'text'),
      ),
    ).thenThrow(exception);

    expect(
      () => useCase(receiverId: 'receiver-1', text: 'Hello'),
      throwsA(same(exception)),
    );
  });
}
