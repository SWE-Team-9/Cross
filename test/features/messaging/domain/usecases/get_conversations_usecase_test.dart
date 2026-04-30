import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_list_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversations_usecase.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository repository;
  late GetConversationsUseCase useCase;

  const participant = ParticipantEntity(
    id: 'user-1',
    displayName: 'Listener One',
    handle: '@listener',
    avatarUrl: null,
  );

  const result = ConversationListPageEntity(
    conversations: <ConversationEntity>[
      ConversationEntity(
        conversationId: 'conversation-1',
        participant: participant,
        lastMessage: null,
        unreadCount: 0,
      ),
    ],
    page: 1,
    limit: 20,
    total: 1,
    hasMore: false,
  );

  setUp(() {
    repository = MockMessagingRepository();
    useCase = GetConversationsUseCase(repository);
  });

  test('calls repository with default values', () async {
    when(
      () => repository.getMyConversations(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) async => result);

    final actual = await useCase();

    expect(actual, result);
    verify(
      () => repository.getMyConversations(
        page: 1,
        limit: 20,
        archived: false,
      ),
    ).called(1);
  });

  test('passes custom values to repository', () async {
    when(
      () => repository.getMyConversations(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) async => result);

    await useCase(page: 3, limit: 10, archived: true);

    verify(
      () => repository.getMyConversations(
        page: 3,
        limit: 10,
        archived: true,
      ),
    ).called(1);
  });

  test('propagates repository errors', () async {
    final exception = Exception('failed');

    when(
      () => repository.getMyConversations(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenThrow(exception);

    expect(
      () => useCase(),
      throwsA(same(exception)),
    );
  });
}
