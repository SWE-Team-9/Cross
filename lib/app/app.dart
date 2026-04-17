import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/deep_links/deep_link_destination.dart';
import '../core/deep_links/deep_link_service.dart';
import '../core/di/injector.dart';
import '../core/notifiers/overlay_notifiers.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/playback/presentation/bloc/player_cubit.dart';
import '../features/playback/presentation/bloc/player_ui_state.dart';
import '../features/playback/presentation/bloc/playback_cubit.dart';
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
          BlocProvider(
            create: (_) => getIt<AuthCubit>(),
          ),
          BlocProvider(
            create: (_) => getIt<PlayerCubit>(),
          ),
          BlocProvider(
            create: (_) => getIt<PlaybackCubit>(),
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
            return BlocBuilder<PlayerCubit, PlayerUIState>(
              builder: (context, playerState) {
                final isPlayerOpen = playerState.isFullScreen;
                // Keep mini-player off non-home surfaces to avoid blocking forms/actions.
                const miniPlayerVisibleRoutes = <String>{
                  AppRoutes.home,
                };

                return _DeepLinkBridge(
                  child: Scaffold(
                    backgroundColor: Colors.black,
                    body: Stack(
                      children: [
                        child ?? const SizedBox.shrink(),
                        // ── Mini player ──────────────────────────────────
                        ValueListenableBuilder<bool>(
                          valueListenable: isTrackSheetOpen,
                          builder: (context, sheetOpen, _) {
                            return ValueListenableBuilder<RouteInformation>(
                              valueListenable: router.routeInformationProvider,
                              builder: (context, routeInfo, __) {
                                final currentPath = routeInfo.uri.path;
                                final showMiniPlayerOnRoute =
                                    miniPlayerVisibleRoutes.contains(currentPath);
                                final hide =
                                    isPlayerOpen || sheetOpen || !showMiniPlayerOnRoute;
                                return Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 70,
                                  child: IgnorePointer(
                                    ignoring: hide,
                                    child: AnimatedSlide(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      offset: hide
                                          ? const Offset(0, 1.2)
                                          : Offset.zero,
                                      child: AnimatedOpacity(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        curve: Curves.easeOut,
                                        opacity: hide ? 0 : 1,
                                        child: const MiniPlayer(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
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

      final pending = deepLinkService.peekLastDestination();
      if (pending is OAuthCallbackDeepLink) {
        deepLinkService.markLastDestinationConsumed();
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
