import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injector.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/playback/presentation/bloc/player_cubit.dart';
import '../features/social/data/repositories/social_repo.dart';
import '../features/playback/presentation/widgets/mini_player.dart';

import 'router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SocialRepo>.value(
          value: getIt<SocialRepo>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Auth (existing)
          BlocProvider(
            create: (_) => getIt<AuthCubit>(),
          ),

          BlocProvider(
            create: (_) => getIt<PlayerCubit>(),
          ),
        ],
        child: MaterialApp.router(
          title: 'SoundCloud Clone',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.orange,
            useMaterial3: true,
          ),
          builder: (context, child) {
            return AnimatedBuilder(
              animation: router.routerDelegate,
              builder: (context, _) {
                final isPlayerOpen =
                    context.watch<PlayerCubit>().state.isFullScreen;

                return Scaffold(
                  body: Stack(
                    children: [
                      child!,
                      if (!isPlayerOpen)
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 70,
                          child: MiniPlayer(),
                        ),
                    ],
                  ),
                );
              },
            );
          },
          routerConfig: router,
        ),
      ),
    );
  }
}
