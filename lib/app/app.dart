import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/deep_links/deep_link_destination.dart';
import '../core/deep_links/deep_link_service.dart';
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
          routerConfig: router,
          builder: (context, child) {
            return _DeepLinkBridge(
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}

class _DeepLinkBridge extends StatefulWidget {
  const _DeepLinkBridge({required this.child});

  final Widget child;

  @override
  State<_DeepLinkBridge> createState() => _DeepLinkBridgeState();
}

class _DeepLinkBridgeState extends State<_DeepLinkBridge> {
  StreamSubscription<DeepLinkDestination>? _subscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final deepLinkService = getIt<DeepLinkService>();

      final pending = deepLinkService.consumeLastDestination();
      if (pending != null) {
        _handleDestination(pending);
      }

      _subscription = deepLinkService.stream.listen(_handleDestination);
    });
  }

  void _handleDestination(DeepLinkDestination destination) {
    if (!mounted) return;

    if (destination is OAuthCallbackDeepLink) {
      context.read<AuthCubit>().handleOAuthCallbackDeepLink(destination);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}