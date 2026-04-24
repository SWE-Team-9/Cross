import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/playlists/presentation/widgets/playlist_track_picker_sheet.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;

  setUp(() async {
    await getIt.reset();
    dioClient = MockDioClient();
    getIt.registerSingleton<DioClient>(dioClient);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget _buildHost({required Set<String> existingTrackIds}) {
    return MaterialApp(
      home: _PickerHost(existingTrackIds: existingTrackIds),
    );
  }

  group('PlaylistTrackPickerSheet', () {
    testWidgets('blank query keeps idle prompt and skips network', (tester) async {
      await tester.pumpWidget(_buildHost(existingTrackIds: const <String>{}));
      await tester.tap(find.text('open picker'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Start typing to search tracks'), findsOneWidget);
      verifyNever(() => dioClient.get(any(), queryParameters: any(named: 'queryParameters')));
    });

    testWidgets('search typing loads and shows tracks', (tester) async {
      when(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: {'q': 'layali', 'limit': 25},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks'),
          data: {
            'tracks': [
              {
                'trackId': 'trk_1',
                'title': 'Layali',
                'artistName': 'Ahmed',
              },
            ],
          },
        ),
      );

      await tester.pumpWidget(_buildHost(existingTrackIds: const <String>{}));
      await tester.tap(find.text('open picker'));
      await tester.pumpAndSettle();

      expect(find.text('Start typing to search tracks'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'layali');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Layali'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
    });

    testWidgets('error while searching shows empty-state message', (tester) async {
      when(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: {'q': 'boom', 'limit': 25},
          )).thenThrow(Exception('network failed'));

      await tester.pumpWidget(_buildHost(existingTrackIds: const <String>{}));
      await tester.tap(find.text('open picker'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'boom');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('No tracks found'), findsOneWidget);
    });

    testWidgets('selecting a result returns selected track and closes sheet',
        (tester) async {
      when(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: {'q': 'echo', 'limit': 25},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks'),
          data: {
            'tracks': [
              {
                'trackId': 'trk_2',
                'title': 'Echoes',
                'artistName': 'Noor',
              },
            ],
          },
        ),
      );

      await tester.pumpWidget(_buildHost(existingTrackIds: const <String>{}));
      await tester.tap(find.text('open picker'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'echo');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Echoes'));
      await tester.pumpAndSettle();

      expect(find.text('selected: trk_2'), findsOneWidget);
      expect(find.text('Search tracks by title or artist'), findsNothing);
    });

    testWidgets('duplicate tracks are disabled and keep sheet open',
        (tester) async {
      when(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: {'q': 'dup', 'limit': 25},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks'),
          data: {
            'tracks': [
              {
                'trackId': 'trk_dup',
                'title': 'Duplicate Track',
                'artistName': 'Artist X',
              },
            ],
          },
        ),
      );

      await tester
          .pumpWidget(_buildHost(existingTrackIds: const <String>{'trk_dup'}));
      await tester.tap(find.text('open picker'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'dup');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.text('Duplicate Track'));
      await tester.pumpAndSettle();

      expect(find.text('selected: none'), findsOneWidget);
      expect(find.text('Search tracks by title or artist'), findsOneWidget);
    });

  });
}

class _PickerHost extends StatefulWidget {
  final Set<String> existingTrackIds;

  const _PickerHost({required this.existingTrackIds});

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends State<_PickerHost> {
  String selectedTrackId = 'none';

  Future<void> _openPicker() async {
    final picked = await PlaylistTrackPickerSheet.show(
      context,
      existingTrackIds: widget.existingTrackIds,
    );

    if (!mounted) return;
    setState(() {
      selectedTrackId = picked?.id ?? 'none';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _openPicker,
              child: const Text('open picker'),
            ),
            const SizedBox(height: 8),
            Text('selected: $selectedTrackId'),
          ],
        ),
      ),
    );
  }
}
