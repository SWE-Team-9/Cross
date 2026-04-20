import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/upload/data/services/audio_picker_permission_service.dart';

class MockAudioPickerPermissionGateway extends Mock
    implements AudioPickerPermissionGateway {}

void main() {
  late MockAudioPickerPermissionGateway mockGateway;
  late AudioPickerPermissionServiceImpl service;

  setUpAll(() {
    registerFallbackValue(AudioPickerPermission.audio);
  });

  setUp(() {
    mockGateway = MockAudioPickerPermissionGateway();

    when(() => mockGateway.statusOf(any())).thenAnswer(
      (_) async => AudioPickerPermissionStatus.denied,
    );
    when(() => mockGateway.request(any())).thenAnswer(
      (_) async => AudioPickerPermissionStatus.denied,
    );

    service = AudioPickerPermissionServiceImpl(
      gateway: mockGateway,
      isAndroidOverride: true,
    );
  });

  group('AudioPickerPermissionServiceImpl', () {
    test('does nothing when runtime permission is not required', () async {
      final nonAndroidService = AudioPickerPermissionServiceImpl(
        gateway: mockGateway,
        isAndroidOverride: false,
      );

      await nonAndroidService.ensurePermissionGranted();

      verifyNever(() => mockGateway.statusOf(AudioPickerPermission.audio));
      verifyNever(() => mockGateway.statusOf(AudioPickerPermission.storage));
      verifyNever(() => mockGateway.request(AudioPickerPermission.audio));
      verifyNever(() => mockGateway.request(AudioPickerPermission.storage));
    });

    test('returns when audio permission is already granted', () async {
      when(
        () => mockGateway.statusOf(AudioPickerPermission.audio),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.granted);

      await service.ensurePermissionGranted();

      verify(() => mockGateway.statusOf(AudioPickerPermission.audio)).called(1);
      verifyNever(() => mockGateway.request(AudioPickerPermission.audio));
      verifyNever(() => mockGateway.statusOf(AudioPickerPermission.storage));
      verifyNever(() => mockGateway.request(AudioPickerPermission.storage));
    });

    test(
        'requests audio permission when initially denied and passes when granted',
        () async {
      when(
        () => mockGateway.statusOf(AudioPickerPermission.audio),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.request(AudioPickerPermission.audio),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.granted);

      await service.ensurePermissionGranted();

      verifyInOrder([
        () => mockGateway.statusOf(AudioPickerPermission.audio),
        () => mockGateway.request(AudioPickerPermission.audio),
      ]);
      verifyNever(() => mockGateway.statusOf(AudioPickerPermission.storage));
      verifyNever(() => mockGateway.request(AudioPickerPermission.storage));
    });

    test('falls back to storage permission when audio is denied', () async {
      when(
        () => mockGateway.statusOf(AudioPickerPermission.audio),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.request(AudioPickerPermission.audio),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.statusOf(AudioPickerPermission.storage),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.request(AudioPickerPermission.storage),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.granted);

      await service.ensurePermissionGranted();

      verifyInOrder([
        () => mockGateway.statusOf(AudioPickerPermission.audio),
        () => mockGateway.request(AudioPickerPermission.audio),
        () => mockGateway.statusOf(AudioPickerPermission.storage),
        () => mockGateway.request(AudioPickerPermission.storage),
      ]);
    });

    test('throws denied error when both permissions are denied', () async {
      when(
        () => mockGateway.statusOf(AudioPickerPermission.audio),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.request(AudioPickerPermission.audio),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.statusOf(AudioPickerPermission.storage),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.request(AudioPickerPermission.storage),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);

      await expectLater(
        service.ensurePermissionGranted(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Audio file permission was denied'),
          ),
        ),
      );
    });

    test(
        'throws permanently denied error when one permission is permanently denied',
        () async {
      when(
        () => mockGateway.statusOf(AudioPickerPermission.audio),
      ).thenAnswer(
        (_) async => AudioPickerPermissionStatus.permanentlyDenied,
      );
      when(
        () => mockGateway.statusOf(AudioPickerPermission.storage),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.request(AudioPickerPermission.storage),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);

      await expectLater(
        service.ensurePermissionGranted(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Audio file permission is permanently denied'),
          ),
        ),
      );
    });

    test(
        'returns when storage permission is already granted after audio is denied',
        () async {
      when(
        () => mockGateway.statusOf(AudioPickerPermission.audio),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.request(AudioPickerPermission.audio),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.statusOf(AudioPickerPermission.storage),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.granted);

      await service.ensurePermissionGranted();

      verifyInOrder([
        () => mockGateway.statusOf(AudioPickerPermission.audio),
        () => mockGateway.request(AudioPickerPermission.audio),
        () => mockGateway.statusOf(AudioPickerPermission.storage),
      ]);
      verifyNever(() => mockGateway.request(AudioPickerPermission.storage));
    });

    test(
        'returns when storage request grants permission after audio is permanently denied',
        () async {
      when(
        () => mockGateway.statusOf(AudioPickerPermission.audio),
      ).thenAnswer(
        (_) async => AudioPickerPermissionStatus.permanentlyDenied,
      );
      when(
        () => mockGateway.statusOf(AudioPickerPermission.storage),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.denied);
      when(
        () => mockGateway.request(AudioPickerPermission.storage),
      ).thenAnswer((_) async => AudioPickerPermissionStatus.granted);

      await service.ensurePermissionGranted();

      verifyInOrder([
        () => mockGateway.statusOf(AudioPickerPermission.audio),
        () => mockGateway.statusOf(AudioPickerPermission.storage),
        () => mockGateway.request(AudioPickerPermission.storage),
      ]);
    });
  });
}
