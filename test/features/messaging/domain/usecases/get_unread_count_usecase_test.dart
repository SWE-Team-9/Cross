import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/unread_count_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_unread_count_usecase.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository repository;
  late GetUnreadCountUseCase useCase;

  const result = UnreadCountEntity(count: 5);

  setUp(() {
    repository = MockMessagingRepository();
    useCase = GetUnreadCountUseCase(repository);
  });

  test('delegates to repository', () async {
    when(repository.getUnreadCount).thenAnswer((_) async => result);

    final actual = await useCase();

    expect(actual, result);
    verify(repository.getUnreadCount).called(1);
  });

  test('propagates repository errors', () async {
    final exception = Exception('failed');

    when(repository.getUnreadCount).thenThrow(exception);

    expect(
      () => useCase(),
      throwsA(same(exception)),
    );
  });
}
