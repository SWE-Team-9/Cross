import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';

import 'app/app.dart';
import 'core/audio/app_audio_handler.dart';
import 'core/deep_links/deep_link_service.dart';
import 'core/di/injector.dart';
import 'features/notifications/data/services/fcm_registration_service.dart';

late AudioHandler audioHandler;

bool _supportsFcmRuntime() {
  if (kIsWeb) return false;

  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supportsFcmRuntime()) {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.instance.getToken().then((token) {
      debugPrint('=== FCM TOKEN ACQUIRED ===');
      debugPrint('Token: $token');
      debugPrint('==========================');
    }).catchError((error) {
      debugPrint('=== FCM TOKEN ERROR ===');
      debugPrint('Error: $error');
      debugPrint('=======================');
    });

    if (kDebugMode) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('╔═══════════════════════════════════════════════');
        debugPrint('║ 📬 FOREGROUND MESSAGE RECEIVED');
        debugPrint('╠═══════════════════════════════════════════════');
        debugPrint('║ Title: ${message.notification?.title}');
        debugPrint('║ Body: ${message.notification?.body}');
        debugPrint('║ Type: ${message.data['type']}');
        debugPrint('║ Actor: ${message.data['actorDisplayName']}');
        debugPrint('║ Track: ${message.data['trackName']}');
        debugPrint('╚═══════════════════════════════════════════════');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('╔═══════════════════════════════════════════════');
        debugPrint('║ 👆 MESSAGE OPENED FROM BACKGROUND');
        debugPrint('╠═══════════════════════════════════════════════');
        debugPrint('║ Title: ${message.notification?.title}');
        debugPrint('║ Body: ${message.notification?.body}');
        debugPrint('║ Type: ${message.data['type']}');
        debugPrint('╚═══════════════════════════════════════════════');
      });
    }
  }

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

  await getIt<FcmRegistrationService>().initialize();
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
