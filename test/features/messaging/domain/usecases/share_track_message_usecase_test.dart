import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/share_track_message_usecase.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository repository;
  late ShareTrackMessageUseCase useCase;

  late MessageEntity result;

  setUp(() {
    repository = MockMessagingRepository();
    useCase = ShareTrackMessageUseCase(repository);

    result = MessageEntity(
      id: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'sender-1',
      receiverId: 'receiver-1',
      type: MessageType.trackShare,
      text: 'Listen',
      isRead: false,
      createdAt: DateTime.utc(2026, 4, 30),
      sharedTrack: null,
      sharedPlaylist: null,
    );
  });

  test('delegates receiverId, trackId, and text to repository', () async {
    when(
      () => repository.shareTrack(
        receiverId: any(named: 'receiverId'),
        trackId: any(named: 'trackId'),
        text: any(named: 'text'),
      ),
    ).thenAnswer((_) async => result);

    final actual = await useCase(
      receiverId: 'receiver-1',
      trackId: 'track-1',
      text: 'Listen',
    );

    expect(actual, result);
    verify(
      () => repository.shareTrack(
        receiverId: 'receiver-1',
        trackId: 'track-1',
        text: 'Listen',
      ),
    ).called(1);
  });

  test('passes null text to repository', () async {
    when(
      () => repository.shareTrack(
        receiverId: any(named: 'receiverId'),
        trackId: any(named: 'trackId'),
        text: any(named: 'text'),
      ),
    ).thenAnswer((_) async => result);

    await useCase(
      receiverId: 'receiver-1',
      trackId: 'track-1',
    );

    verify(
      () => repository.shareTrack(
        receiverId: 'receiver-1',
        trackId: 'track-1',
        text: null,
      ),
    ).called(1);
  });

  test('propagates repository errors', () async {
    final exception = Exception('failed');

    when(
      () => repository.shareTrack(
        receiverId: any(named: 'receiverId'),
        trackId: any(named: 'trackId'),
        text: any(named: 'text'),
      ),
    ).thenThrow(exception);

    expect(
      () => useCase(receiverId: 'receiver-1', trackId: 'track-1'),
      throwsA(same(exception)),
    );
  });
}
