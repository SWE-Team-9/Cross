import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart'
    as auth_domain;
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/playlists/presentation/widgets/playlist_track_picker_sheet.dart';

class MockDioClient extends Mock implements DioClient {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockDioClient dioClient;
  late MockAuthCubit authCubit;

  const currentUser = auth_domain.User(
    id: 'user-1',
    email: 'ali@example.com',
    handle: 'ali',
  );

  setUp(() async {
    await getIt.reset();
    dioClient = MockDioClient();
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthAuthenticated(currentUser));
    getIt.registerSingleton<DioClient>(dioClient);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget _buildHost({required Set<String> existingTrackIds}) {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp(
        home: _PickerHost(existingTrackIds: existingTrackIds),
      ),
    );
  }

  void stubMyTracks([
    List<Map<String, dynamic>> tracks = const <Map<String, dynamic>>[],
  ]) {
    when(() => dioClient.get(
          '/api/v1/users/user-1/tracks',
          queryParameters: {'page': 1, 'limit': 50},
        )).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/users/user-1/tracks'),
        data: {'tracks': tracks},
      ),
    );
  }

  group('PlaylistTrackPickerSheet', () {
    testWidgets('opening picker loads current user tracks', (tester) async {
      stubMyTracks([
        {
          'trackId': 'trk_mine',
          'title': 'My Upload',
          'artistName': 'Ali',
        },
      ]);

      await tester.pumpWidget(_buildHost(existingTrackIds: const <String>{}));
      await tester.tap(find.text('open picker'));
      await tester.pumpAndSettle();

      expect(find.text('My Upload'), findsOneWidget);
      expect(find.text('Ali'), findsOneWidget);
      verify(() => dioClient.get(
            '/api/v1/users/user-1/tracks',
            queryParameters: {'page': 1, 'limit': 50},
          )).called(1);
    });

    testWidgets('search typing loads and shows tracks', (tester) async {
      stubMyTracks();
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

      await tester.enterText(find.byType(TextField), 'layali');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Layali'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
    });

    testWidgets('search filters current user tracks before global search',
        (tester) async {
      stubMyTracks([
        {
          'trackId': 'trk_mine',
          'title': 'Bedroom Mix',
          'artistName': 'Ali',
        },
      ]);

      await tester.pumpWidget(_buildHost(existingTrackIds: const <String>{}));
      await tester.tap(find.text('open picker'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'bedroom');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Bedroom Mix'), findsOneWidget);
      verifyNever(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: any(named: 'queryParameters'),
          ));
    });

    testWidgets('error while searching shows empty-state message',
        (tester) async {
      stubMyTracks();
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

    testWidgets('selecting a result returns selected tracks and closes sheet',
        (tester) async {
      stubMyTracks();
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
      await tester.pump();
      await tester.ensureVisible(find.text('Add selected track'));
      await tester.tap(find.text('Add selected track'));
      await tester.pumpAndSettle();

      expect(find.text('selected: trk_2'), findsOneWidget);
      expect(find.text('Search tracks by title or artist'), findsNothing);
    });

    testWidgets('selecting multiple results returns all selected tracks',
        (tester) async {
      stubMyTracks([
        {
          'trackId': 'trk_1',
          'title': 'First Track',
          'artistName': 'Ali',
        },
        {
          'trackId': 'trk_2',
          'title': 'Second Track',
          'artistName': 'Ali',
        },
      ]);

      await tester.pumpWidget(_buildHost(existingTrackIds: const <String>{}));
      await tester.tap(find.text('open picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('First Track'));
      await tester.tap(find.text('Second Track'));
      await tester.pump();

      expect(find.text('2 selected'), findsOneWidget);
      await tester.tap(find.text('Add 2 tracks'));
      await tester.pumpAndSettle();

      expect(find.text('selected: trk_1,trk_2'), findsOneWidget);
    });

    testWidgets('duplicate tracks are disabled and keep sheet open',
        (tester) async {
      stubMyTracks();
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
  String selectedTrackIds = 'none';

  Future<void> _openPicker() async {
    final pickedTracks = await PlaylistTrackPickerSheet.show(
      context,
      existingTrackIds: widget.existingTrackIds,
    );

    if (!mounted) return;
    setState(() {
      selectedTrackIds = pickedTracks.isEmpty
          ? 'none'
          : pickedTracks.map((track) => track.id).join(',');
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
            Text('selected: $selectedTrackIds'),
          ],
        ),
      ),
    );
  }
}
