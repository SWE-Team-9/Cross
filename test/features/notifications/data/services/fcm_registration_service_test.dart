import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversation_meta_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';
import 'package:soundcloud_clone/features/notifications/data/services/fcm_registration_service.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/device_use_cases.dart';

class MockRegisterDeviceUseCase extends Mock implements RegisterDeviceUseCase {}

class MockGetConversationMetaUseCase extends Mock
    implements GetConversationMetaUseCase {}

class MockGetOrCreateDirectConversationUseCase extends Mock
    implements GetOrCreateDirectConversationUseCase {}

void main() {
  late MockRegisterDeviceUseCase registerDeviceUseCase;
  late MockGetConversationMetaUseCase getConversationMetaUseCase;
  late MockGetOrCreateDirectConversationUseCase getOrCreateDirectConversationUseCase;
  late FcmRegistrationService service;

  setUp(() {
    registerDeviceUseCase = MockRegisterDeviceUseCase();
    getConversationMetaUseCase = MockGetConversationMetaUseCase();
    getOrCreateDirectConversationUseCase =
        MockGetOrCreateDirectConversationUseCase();
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    service = FcmRegistrationService(
      registerDeviceUseCase,
      getConversationMetaUseCase,
      getOrCreateDirectConversationUseCase,
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('syncToken returns false on unsupported platforms', () async {
    final result = await service.syncToken();

    expect(result, isFalse);
    verifyNever(() => registerDeviceUseCase(
          deviceToken: any(named: 'deviceToken'),
          platform: any(named: 'platform'),
        ));
  });

  test('dispose is safe before initialization', () async {
    await service.dispose();
  });

  test('consume helpers return null before any notification is opened', () {
    expect(service.consumeLastOpenedConversation(), isNull);
    expect(service.consumeLastOpenedNotification(), isNull);
  });
}
