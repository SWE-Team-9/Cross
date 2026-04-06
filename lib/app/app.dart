import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injector.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/playback/presentation/bloc/player_cubit.dart';
import '../features/social/data/repositories/social_repo.dart';

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
            create: (_) => PlayerCubit(getIt()),
          ),
        ],
        child: MaterialApp.router(
          title: 'SoundCloud Clone',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.orange,
            useMaterial3: true,
          ),
          routerConfig: router,
        ),
      ),
    );
  }
}
