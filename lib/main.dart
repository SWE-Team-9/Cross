import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/injector.dart';
import 'package:audio_service/audio_service.dart';
import 'core/audio/app_audio_handler.dart';

late AudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  audioHandler = await AudioService.init(
    builder: () => AppAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.soundcloud.app',
      androidNotificationChannelName: 'Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  await setupDependencies();

  runApp(const App());
}
