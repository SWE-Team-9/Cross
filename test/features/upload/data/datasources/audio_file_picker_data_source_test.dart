import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/audio_file_picker_data_source.dart';
import 'package:soundcloud_clone/features/upload/data/services/audio_picker_permission_service.dart';
import 'package:soundcloud_clone/core/errors/upload_picker_exceptions.dart';

class MockFilePicker extends Mock
    with MockPlatformInterfaceMixin
    implements FilePicker {}

class MockAudioPickerPermissionService extends Mock
    implements AudioPickerPermissionService {}

void main() {
  late MockFilePicker mockFilePicker;
  late MockAudioPickerPermissionService mockPermissionService;
  late AudioFilePickerDataSourceImpl dataSource;

  setUp(() {
    mockFilePicker = MockFilePicker();
    mockPermissionService = MockAudioPickerPermissionService();

    FilePicker.platform = mockFilePicker;
    when(() => mockPermissionService.ensurePermissionGranted())
        .thenAnswer((_) => Future<void>.value());
    dataSource = AudioFilePickerDataSourceImpl(mockPermissionService);
  });

  group('pickAudioFile', () {
    test('requests permission before opening picker', () async {
      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          )).thenAnswer(
        (_) async => FilePickerResult(
          <PlatformFile>[
            PlatformFile(
              name: 'track.mp3',
              path: '/tmp/track.mp3',
              size: 1024,
            ),
          ],
        ),
      );

      await dataSource.pickAudioFile();

      verifyInOrder([
        () => mockPermissionService.ensurePermissionGranted(),
        () => mockFilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: const ['mp3', 'wav'],
              allowMultiple: false,
            ),
      ]);
    });

    test('returns null when picker result is null', () async {
      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          )).thenAnswer((_) async => null);

      final result = await dataSource.pickAudioFile();

      expect(result, isNull);
    });

    test('returns null when picker result has no files', () async {
      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          )).thenAnswer(
        (_) async => FilePickerResult(const <PlatformFile>[]),
      );

      final result = await dataSource.pickAudioFile();

      expect(result, isNull);
    });

    test('returns dto when mp3 file is selected', () async {
      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          )).thenAnswer(
        (_) async => FilePickerResult(
          <PlatformFile>[
            PlatformFile(
              name: 'track.mp3',
              path: '/tmp/track.mp3',
              size: 1024,
            ),
          ],
        ),
      );

      final result = await dataSource.pickAudioFile();

      expect(result, isNotNull);
      expect(result!.name, 'track.mp3');
      expect(result.extension, 'mp3');
      expect(result.path, '/tmp/track.mp3');
      expect(result.sizeInBytes, 1024);
    });

    test('falls back to file name extension when picker extension is absent',
        () async {
      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          )).thenAnswer(
        (_) async => FilePickerResult(
          <PlatformFile>[
            PlatformFile(
              name: 'track.WAV',
              path: '/tmp/track.WAV',
              size: 2048,
            ),
          ],
        ),
      );

      final result = await dataSource.pickAudioFile();

      expect(result, isNotNull);
      expect(result!.extension, 'wav');
    });

    test('throws when extension is unsupported', () async {
      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          )).thenAnswer(
        (_) async => FilePickerResult(
          <PlatformFile>[
            PlatformFile(
              name: 'track.aac',
              path: '/tmp/track.aac',
              size: 2048,
            ),
          ],
        ),
      );

      expect(
        () => dataSource.pickAudioFile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Only MP3 and WAV files are allowed.'),
          ),
        ),
      );
    });

    test('wraps permission exceptions', () async {
      when(() => mockPermissionService.ensurePermissionGranted()).thenThrow(
        Exception(
          'Audio file permission was denied. Please allow access to continue.',
        ),
      );

      expect(
        () => dataSource.pickAudioFile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'Failed to pick audio file: Audio file permission was denied.',
            ),
          ),
        ),
      );

      verifyNever(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          ));
    });

    test('wraps picker exceptions', () async {
      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          )).thenThrow(Exception('picker crashed'));

      expect(
        () => dataSource.pickAudioFile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to pick audio file: picker crashed'),
          ),
        ),
      );
    });

    test(
        'throws when picker extension is absent and file name has no extension',
        () async {
      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          )).thenAnswer(
        (_) async => FilePickerResult(
          <PlatformFile>[
            PlatformFile(
              name: 'track',
              path: '/tmp/track',
              size: 1024,
            ),
          ],
        ),
      );

      expect(
        () => dataSource.pickAudioFile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Only MP3 and WAV files are allowed.'),
          ),
        ),
      );
    });

    test('normalizes extension from file name when casing is mixed', () async {
      when(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          )).thenAnswer(
        (_) async => FilePickerResult(
          <PlatformFile>[
            PlatformFile(
              name: 'track.Mp3',
              path: '/tmp/track.Mp3',
              size: 1024,
            ),
          ],
        ),
      );

      final result = await dataSource.pickAudioFile();

      expect(result, isNotNull);
      expect(result!.extension, 'mp3');
    });
    test('rethrows permanently denied permission exception', () async {
      when(() => mockPermissionService.ensurePermissionGranted()).thenThrow(
        const UploadPickerPermissionPermanentlyDeniedException(
          'Audio file permission is permanently denied. Please enable it from system settings.',
        ),
      );

      expect(
        () => dataSource.pickAudioFile(),
        throwsA(
          isA<UploadPickerPermissionPermanentlyDeniedException>().having(
            (e) => e.message,
            'message',
            contains('Audio file permission is permanently denied'),
          ),
        ),
      );

      verifyNever(() => mockFilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['mp3', 'wav'],
            allowMultiple: false,
          ));
    });
  });
}
