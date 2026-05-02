import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';

// 🔥 Mock service
class MockAudioPlayerService extends Mock implements AudioPlayerService {
  @override
  Stream<PlayerState> get playerStateStream =>
      const Stream<PlayerState>.empty();

  @override
  Future<void> play(track) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {}
}

Widget wrapWithPlayerCubit(Widget child) {
  return MaterialApp(
    home: BlocProvider<PlayerCubit>(
      create: (_) => PlayerCubit(MockAudioPlayerService()),
      child: child,
    ),
  );
}
