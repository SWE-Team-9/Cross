import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notifications_result.dart';
import 'package:soundcloud_clone/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/device_use_cases.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  late MockNotificationsRepository repo;
  late RegisterDeviceUseCase register;
  late RemoveDeviceUseCase remove;

  setUp(() {
    repo = MockNotificationsRepository();
    register = RegisterDeviceUseCase(repo);
    remove = RemoveDeviceUseCase(repo);
  });

  test('register device forwards to repository and returns success', () async {
    when(() => repo.registerDevice(deviceToken: 't', platform: 'android'))
        .thenAnswer((_) async => const NotificationsResult.success(null));

    final res = await register.call(deviceToken: 't', platform: 'android');
    expect(res, isA<NotificationsSuccess>());
  });

  test('remove device forwards to repository and returns failure', () async {
    when(() => repo.removeDevice('d1')).thenAnswer(
      (_) async => const NotificationsResult.failure(ServerFailure('err')),
    );

    final res = await remove.call('d1');
    expect(res, isA<NotificationsFailure>());
  });
}
