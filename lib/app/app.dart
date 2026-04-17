import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/deep_links/deep_link_destination.dart';
import '../core/deep_links/deep_link_service.dart';
import '../core/di/injector.dart';
import '../core/notifiers/overlay_notifiers.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/auth/presentation/routes/auth_routes.dart';
import '../features/playback/presentation/bloc/player_cubit.dart';
import '../features/playback/presentation/bloc/player_ui_state.dart';
import '../features/playback/presentation/bloc/playback_cubit.dart';
import '../features/playback/presentation/widgets/mini_player.dart';
import '../features/social/data/repositories/social_repo.dart';
import 'router.dart';

// Routes where the mini-player must stay hidden (auth/onboarding/full player).
const Set<String> _miniPlayerHiddenRoutes = <String>{
  AuthRoutes.splash,
  AuthRoutes.welcome,
  AuthRoutes.login,
  AuthRoutes.register,
  AuthRoutes.completeProfile,
  AuthRoutes.forgotPassword,
  AuthRoutes.resetPassword,
  AuthRoutes.verifyEmail,
  AuthRoutes.oauthDebug,
  AppRoutes.player,
};
const double _miniPlayerReservedBottomSpace = 74;
const double _miniPlayerBottomOffset = 70;

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
                final hasMiniPlayerTrack =
                    playerState.currentTrack != null && playerState.showMiniPlayer;

                return _DeepLinkBridge(
                  child: Scaffold(
                    backgroundColor: Colors.black,
                    body: ValueListenableBuilder<bool>(
                      valueListenable: isTrackSheetOpen,
                      builder: (context, sheetOpen, _) {
                        return ValueListenableBuilder<RouteInformation>(
                          valueListenable: router.routeInformationProvider,
                          builder: (context, routeInfo, __) {
                            final currentPath = routeInfo.uri.path;
                            final showMiniPlayerOnRoute =
                                !_miniPlayerHiddenRoutes.contains(currentPath);
                            final showMiniPlayer = hasMiniPlayerTrack &&
                                showMiniPlayerOnRoute &&
                                !isPlayerOpen &&
                                !sheetOpen;
                            final reservedBottom =
                                showMiniPlayer ? _miniPlayerReservedBottomSpace : 0.0;

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: AnimatedPadding(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    padding: EdgeInsets.only(bottom: reservedBottom),
                                    child: child ?? const SizedBox.shrink(),
                                  ),
                                ),
                                if (hasMiniPlayerTrack && showMiniPlayerOnRoute)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: _miniPlayerBottomOffset,
                                    child: IgnorePointer(
                                      ignoring: !showMiniPlayer,
                                      child: AnimatedSlide(
                                        duration: const Duration(milliseconds: 220),
                                        curve: Curves.easeOutCubic,
                                        offset: showMiniPlayer
                                            ? Offset.zero
                                            : const Offset(0, 1.2),
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 180),
                                          curve: Curves.easeOut,
                                          opacity: showMiniPlayer ? 1 : 0,
                                          child: const MiniPlayer(),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
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
      router.go(AuthRoutes.oauthDebug, extra: destination);
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
