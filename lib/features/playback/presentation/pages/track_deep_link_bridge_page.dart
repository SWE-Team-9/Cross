import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../bloc/track_loader_cubit.dart';
import '../bloc/track_loader_state.dart';

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
  bool _timedOut = false;
  String? _artistHandle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    // Add 15-second timeout for loading
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted &&
          !_navigated &&
          context.read<TrackLoaderCubit>().state
              is! TrackLoaderReady) {
        setState(() => _timedOut = true);
      }
    });
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

    if (_artistHandle == null || _artistHandle!.isEmpty) {
      _handleError('Artist information not available.');
      return;
    }

    // Use pushReplacement to replace the bridge page in the stack
    context.pushReplacement(
      '/profile/$_artistHandle',
    );
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
    if (_timedOut) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF5500), size: 48),
              const SizedBox(height: 20),
              const Text(
                'Loading took too long',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5500),
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return BlocListener<TrackLoaderCubit, TrackLoaderState>(
      listener: (context, state) {
        switch (state) {
          case TrackLoaderReady(:final detail):
            _artistHandle = detail.artistHandle;
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
