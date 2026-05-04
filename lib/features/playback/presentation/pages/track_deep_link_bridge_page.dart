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
    this.handle,
    this.slug,
  }) : assert(
          trackId != null ||
              secretToken != null ||
              (handle != null && slug != null),
          'Either trackId, secretToken, or handle+slug must be provided.',
        );

  final String? trackId;
  final String? secretToken;
  final String? handle;
  final String? slug;

  @override
  State<TrackDeepLinkBridgePage> createState() =>
      _TrackDeepLinkBridgePageState();
}

class _TrackDeepLinkBridgePageState extends State<TrackDeepLinkBridgePage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final cubit = context.read<TrackLoaderCubit>();

    if (widget.secretToken != null) {
      cubit.loadBySecretToken(widget.secretToken!);
    } else if (widget.handle != null && widget.slug != null) {
      // ✅ يبني الـ slug URL ويبعته للـ cubit
      cubit.loadBySlug(widget.handle!, widget.slug!);
    } else {
      cubit.loadByTrackId(widget.trackId!);
    }
  }

  void _openPlayer() {
    if (_navigated) return;
    _navigated = true;

    final GoRouter? router = GoRouter.maybeOf(context);

    if (router != null) {
      context.read<PlayerCubit>().openFullPlayer();
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
  }

  void _handleError(String message) {
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
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrackLoaderCubit, TrackLoaderState>(
      listener: (context, state) {
        switch (state) {
          case TrackLoaderReady():
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openPlayer();
            });

          case TrackLoaderError(:final message):
            _handleError(message);

          case TrackLoaderLoading():
          case TrackLoaderIdle():
            break;
        }
      },
      child: const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
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
        ),
      ),
    );
  }
}
