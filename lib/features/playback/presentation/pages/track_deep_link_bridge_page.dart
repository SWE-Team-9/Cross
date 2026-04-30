import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../bloc/player_cubit.dart';
import '../bloc/track_loader_cubit.dart';
import '../bloc/track_loader_state.dart';
import 'full_player_page.dart';

class TrackDeepLinkBridgePage extends StatefulWidget {
  const TrackDeepLinkBridgePage({
    super.key,
    this.trackId,
    this.secretToken,
  }) : assert(
          trackId != null || secretToken != null,
          'Either trackId or secretToken must be provided.',
        );

  final String? trackId;
  final String? secretToken;

  @override
  State<TrackDeepLinkBridgePage> createState() =>
      _TrackDeepLinkBridgePageState();
}

class _TrackDeepLinkBridgePageState extends State<TrackDeepLinkBridgePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final cubit = context.read<TrackLoaderCubit>();
    if (widget.secretToken != null) {
      cubit.loadBySecretToken(widget.secretToken!);
    } else {
      cubit.loadByTrackId(widget.trackId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrackLoaderCubit, TrackLoaderState>(
      listener: (context, state) {
        switch (state) {
          case TrackLoaderReady():
            final GoRouter? router = GoRouter.maybeOf(context);
            if (router != null) {
              context.replace(AppRoutes.player);
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: context.read<PlayerCubit>(),
                    child: const FullPlayerPage(),
                  ),
                ),
              );
            }

          case TrackLoaderError(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: const Color(0xFFFF5500),
                behavior: SnackBarBehavior.floating,
              ),
            );

            final GoRouter? router = GoRouter.maybeOf(context);
            if (router != null) {
              context.go(AppRoutes.home);
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (_) => false,
              );
            }

          case TrackLoaderLoading():
          case TrackLoaderIdle():
            break;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<TrackLoaderCubit, TrackLoaderState>(
          builder: (context, state) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFF5500),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Opening track...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
