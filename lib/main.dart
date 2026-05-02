import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';

import 'app/app.dart';
import 'core/audio/app_audio_handler.dart';
import 'core/deep_links/deep_link_service.dart';
import 'core/di/injector.dart';

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

  await getIt<DeepLinkService>().init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SubscriptionCubit>(
          create: (_) => getIt<SubscriptionCubit>()..loadSubscription(),
        ),
        BlocProvider<OfflineCubit>.value(
          value: getIt<OfflineCubit>(),
        ),
      ],
      child: App(),
    ),
  );
}