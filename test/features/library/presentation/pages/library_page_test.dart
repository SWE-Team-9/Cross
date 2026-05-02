import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/library/presentation/bloc/library_cubit.dart';
import 'package:soundcloud_clone/features/library/presentation/bloc/library_state.dart';
import 'package:soundcloud_clone/features/library/presentation/pages/library_page.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockPlayerCubit extends Mock implements PlayerCubit {}

class MockRecentlyPlayedCubit extends MockCubit<List<Track>>
    implements RecentlyPlayedCubit {}

class MockLibraryCubit extends MockCubit<LibraryState>
    implements LibraryCubit {}

void main() {
  late MockAuthCubit authCubit;
  late MockPlayerCubit playerCubit;
  late MockRecentlyPlayedCubit recentlyPlayedCubit;
  late MockLibraryCubit libraryCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    playerCubit = MockPlayerCubit();
    recentlyPlayedCubit = MockRecentlyPlayedCubit();
    libraryCubit = MockLibraryCubit();

    when(() => authCubit.state).thenReturn(
      AuthAuthenticated(_user()),
    );
    when(() => playerCubit.state).thenReturn(
      const PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.idle,
          position: Duration.zero,
        ),
      ),
    );
    when(() => recentlyPlayedCubit.state).thenReturn(const <Track>[]);
    when(() => recentlyPlayedCubit.loadListeningHistory()).thenAnswer(
      (_) async {},
    );
    when(() => libraryCubit.state).thenReturn(
      LibraryState.initial().copyWith(
        likedPlaylists: [
          _playlist(id: 'liked_1', title: 'Liked Playlist'),
        ],
        recentPlaylists: [
          _playlist(id: 'recent_1', title: 'Recent Playlist'),
        ],
      ),
    );
    when(() => libraryCubit.loadLibraryPlaylists()).thenAnswer((_) async {});

    GetIt.I.registerSingleton<RecentlyPlayedCubit>(recentlyPlayedCubit);
    GetIt.I.registerSingleton<LibraryCubit>(libraryCubit);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('LibraryPage', () {
    testWidgets('renders playlist sections from LibraryCubit', (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<PlayerCubit>.value(value: playerCubit),
          ],
          child: const MaterialApp(
            home: LibraryPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Library'), findsWidgets);
      expect(find.text('Liked playlists'), findsOneWidget);
      expect(find.text('Liked Playlist'), findsOneWidget);
      expect(find.text('Recently played playlists'), findsOneWidget);
      expect(find.text('Recent Playlist'), findsOneWidget);

      verify(() => recentlyPlayedCubit.loadListeningHistory()).called(1);
      verify(() => libraryCubit.loadLibraryPlaylists()).called(1);
    });

    testWidgets('shows empty playlist messages from empty LibraryCubit state',
        (tester) async {
      when(() => libraryCubit.state).thenReturn(LibraryState.initial());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<PlayerCubit>.value(value: playerCubit),
          ],
          child: const MaterialApp(
            home: LibraryPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('No liked playlists yet'), findsOneWidget);
      expect(find.text('No recently played playlists yet'), findsOneWidget);
      expect(find.text('No recently played tracks yet'), findsOneWidget);
    });
  });
}

User _user() {
  return const User(
    id: 'user_1',
    email: 'user@example.com',
    displayName: 'Ali',
    handle: 'ali',
    isVerified: true,
  );
}

PlaylistEntity _playlist({
  required String id,
  required String title,
}) {
  return PlaylistEntity(
    playlistId: id,
    title: title,
    description: '',
    visibility: PlaylistVisibility.publicPlaylist,
    secretToken: null,
    coverImageUrl: null,
    owner: const PlaylistOwner(
      id: 'owner_1',
      displayName: 'Owner One',
    ),
    tracks: const [],
    tracksCount: 0,
    likesCount: 0,
  );
}
