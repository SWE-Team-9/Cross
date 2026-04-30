import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/audio_file_picker_data_source.dart';
import 'package:soundcloud_clone/features/upload/data/dto/picked_audio_file_dto.dart';
import 'package:soundcloud_clone/features/upload/data/repositories/upload_repository_impl.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/picked_audio_file.dart';

class MockAudioFilePickerDataSource extends Mock
    implements AudioFilePickerDataSource {}

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockAudioFilePickerDataSource mockAudioFilePickerDataSource;
  late MockDioClient mockDioClient;
  late UploadRepositoryImpl repository;

  const tPickedAudioFileDto = PickedAudioFileDto(
    name: 'test_audio.wav',
    extension: 'wav',
    sizeInBytes: 2048,
    path: '/storage/emulated/0/Download/test_audio.wav',
  );

  const tPickedAudioFile = PickedAudioFile(
    name: 'test_audio.wav',
    extension: 'wav',
    sizeInBytes: 2048,
    path: '/storage/emulated/0/Download/test_audio.wav',
  );

  setUp(() {
    mockAudioFilePickerDataSource = MockAudioFilePickerDataSource();
    mockDioClient = MockDioClient();
    repository = UploadRepositoryImpl(mockAudioFilePickerDataSource);
  });

  group('UploadRepositoryImpl', () {
    test('should return mapped PickedAudioFile when datasource returns dto',
        () async {
      when(() => mockAudioFilePickerDataSource.pickAudioFile())
          .thenAnswer((_) async => tPickedAudioFileDto);

      final result = await repository.pickAudioFile();

      expect(result, isA<PickedAudioFile>());
      expect(result?.name, tPickedAudioFile.name);
      expect(result?.extension, tPickedAudioFile.extension);
      expect(result?.sizeInBytes, tPickedAudioFile.sizeInBytes);
      expect(result?.path, tPickedAudioFile.path);

      verify(() => mockAudioFilePickerDataSource.pickAudioFile()).called(1);
      verifyNoMoreInteractions(mockAudioFilePickerDataSource);
    });

    test('should return null when datasource returns null', () async {
      when(() => mockAudioFilePickerDataSource.pickAudioFile())
          .thenAnswer((_) async => null);

      final result = await repository.pickAudioFile();

      expect(result, isNull);
      verify(() => mockAudioFilePickerDataSource.pickAudioFile()).called(1);
      verifyNoMoreInteractions(mockAudioFilePickerDataSource);
    });

    test('should rethrow when datasource throws', () async {
      when(() => mockAudioFilePickerDataSource.pickAudioFile())
          .thenThrow(Exception('picker failed'));

      expect(
        () => repository.pickAudioFile(),
        throwsA(isA<Exception>()),
      );

      verify(() => mockAudioFilePickerDataSource.pickAudioFile()).called(1);
      verifyNoMoreInteractions(mockAudioFilePickerDataSource);
    });

    group('uploadTrack', () {
      test('throws when DioClient is not configured', () async {
        await expectLater(
          () => repository.uploadTrack(
            file: tPickedAudioFile,
            title: 'My Song',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('throws when picked file path is missing', () async {
        final repoWithClient = UploadRepositoryImpl(
          mockAudioFilePickerDataSource,
          dioClient: mockDioClient,
        );

        const fileWithoutPath = PickedAudioFile(
          name: 'song.wav',
          extension: 'wav',
          sizeInBytes: 123,
          path: null,
        );

        await expectLater(
          () => repoWithClient.uploadTrack(
            file: fileWithoutPath,
            title: 'My Song',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('returns track result from flat payload', () async {
        final temp = await Directory.systemTemp.createTemp('upload_repo_test');
        final tempFile = File('${temp.path}/audio.wav');
        await tempFile.writeAsBytes(const [1, 2, 3, 4]);

        final repoWithClient = UploadRepositoryImpl(
          mockAudioFilePickerDataSource,
          dioClient: mockDioClient,
        );

        final picked = PickedAudioFile(
          name: 'audio.wav',
          extension: 'wav',
          sizeInBytes: 4,
          path: tempFile.path,
        );

        when(
          () => mockDioClient.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.tracks),
            data: {'trackId': 'track-1', 'status': 'PROCESSING'},
          ),
        );

        final result = await repoWithClient.uploadTrack(
          file: picked,
          title: ' My Song ',
          genre: ' Rock ',
        );

        expect(result.trackId, 'track-1');
        expect(result.status, 'PROCESSING');

        verify(
          () => mockDioClient.post(
            ApiConstants.tracks,
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).called(1);
      });

      test('serializes tags as repeated tags[] fields for multipart upload',
          () async {
        final temp = await Directory.systemTemp.createTemp('upload_repo_test4');
        final tempFile = File('${temp.path}/audio4.wav');
        await tempFile.writeAsBytes(const [1, 2, 3]);

        final repoWithClient = UploadRepositoryImpl(
          mockAudioFilePickerDataSource,
          dioClient: mockDioClient,
        );

        final picked = PickedAudioFile(
          name: 'audio4.wav',
          extension: 'wav',
          sizeInBytes: 3,
          path: tempFile.path,
        );

        when(
          () => mockDioClient.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.tracks),
            data: {'trackId': 'track-4', 'status': 'PROCESSING'},
          ),
        );

        await repoWithClient.uploadTrack(
          file: picked,
          title: 'Song',
          tags: const ['lofi'],
        );

        final captured = verify(
          () => mockDioClient.post(
            ApiConstants.tracks,
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          ),
        ).captured.single as FormData;

        final tagFields = captured.fields
            .where((entry) => entry.key == 'tags[]')
            .map((entry) => entry.value)
            .toList();

        expect(tagFields, equals(const ['lofi']));
      });

      test('converts genre slugs to api labels for multipart upload', () async {
        final temp = await Directory.systemTemp.createTemp('upload_repo_test5');
        final tempFile = File('${temp.path}/audio5.wav');
        await tempFile.writeAsBytes(const [1, 2, 3]);

        final repoWithClient = UploadRepositoryImpl(
          mockAudioFilePickerDataSource,
          dioClient: mockDioClient,
        );

        final picked = PickedAudioFile(
          name: 'audio5.wav',
          extension: 'wav',
          sizeInBytes: 3,
          path: tempFile.path,
        );

        when(
          () => mockDioClient.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.tracks),
            data: {'trackId': 'track-5', 'status': 'PROCESSING'},
          ),
        );

        await repoWithClient.uploadTrack(
          file: picked,
          title: 'Song',
          genre: 'sha3by',
        );

        final captured = verify(
          () => mockDioClient.post(
            ApiConstants.tracks,
            data: captureAny(named: 'data'),
            options: any(named: 'options'),
          ),
        ).captured.single as FormData;

        final genreField = captured.fields.singleWhere(
          (entry) => entry.key == 'genre',
        );

        expect(genreField.value, 'Sha3by');
      });

      test('extracts nested track payload and default status', () async {
        final temp = await Directory.systemTemp.createTemp('upload_repo_test2');
        final tempFile = File('${temp.path}/audio2.wav');
        await tempFile.writeAsBytes(const [9, 8, 7]);

        final repoWithClient = UploadRepositoryImpl(
          mockAudioFilePickerDataSource,
          dioClient: mockDioClient,
        );

        final picked = PickedAudioFile(
          name: 'audio2.wav',
          extension: 'wav',
          sizeInBytes: 3,
          path: tempFile.path,
        );

        when(
          () => mockDioClient.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.tracks),
            data: {
              'track': {'id': 'nested-id'}
            },
          ),
        );

        final result = await repoWithClient.uploadTrack(
          file: picked,
          title: 'Song',
        );

        expect(result.trackId, 'nested-id');
        expect(result.status, 'PROCESSING');
      });

      test('throws FormatException when upload response has no track id',
          () async {
        final temp = await Directory.systemTemp.createTemp('upload_repo_test3');
        final tempFile = File('${temp.path}/audio3.wav');
        await tempFile.writeAsBytes(const [5, 5, 5]);

        final repoWithClient = UploadRepositoryImpl(
          mockAudioFilePickerDataSource,
          dioClient: mockDioClient,
        );

        final picked = PickedAudioFile(
          name: 'audio3.wav',
          extension: 'wav',
          sizeInBytes: 3,
          path: tempFile.path,
        );

        when(
          () => mockDioClient.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.tracks),
            data: {'status': 'DONE'},
          ),
        );

        await expectLater(
          () => repoWithClient.uploadTrack(file: picked, title: 'Song'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('getTrackStatus', () {
      test('throws when DioClient is not configured', () async {
        await expectLater(
          () => repository.getTrackStatus(trackId: 't-1'),
          throwsA(isA<Exception>()),
        );
      });

      test('returns status from nested data payload', () async {
        final repoWithClient = UploadRepositoryImpl(
          mockAudioFilePickerDataSource,
          dioClient: mockDioClient,
        );

        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/tracks/t-1/status'),
            data: {
              'data': {'status': 'DONE'}
            },
          ),
        );

        final result = await repoWithClient.getTrackStatus(trackId: 't-1');

        expect(result, 'DONE');
      });

      test('throws FormatException when status is missing', () async {
        final repoWithClient = UploadRepositoryImpl(
          mockAudioFilePickerDataSource,
          dioClient: mockDioClient,
        );

        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/tracks/t-2/status'),
            data: {'data': {}},
          ),
        );

        await expectLater(
          () => repoWithClient.getTrackStatus(trackId: 't-2'),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}
