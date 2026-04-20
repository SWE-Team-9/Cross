import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../bloc/auth_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  VideoPlayerController? _videoController;
  Timer? _splashTimeout;
  String? _pendingRoute;
  bool _videoCompleted = false;

  @override
  void initState() {
    super.initState();

    // Keep startup from hanging forever if media playback fails silently.
    _splashTimeout = Timer(const Duration(seconds: 8), _markVideoCompleted);

    context.read<AuthCubit>().checkAuthStatus();
    _initializeSplashVideo();
  }

  Future<void> _initializeSplashVideo() async {
    try {
      final controller = VideoPlayerController.asset(
        'assets/videos/splash.mp4',
      );
      _videoController = controller;

      await controller.initialize();
      if (!mounted) return;

      controller
        ..setLooping(false)
        ..play();
      controller.addListener(_handleVideoTick);

      setState(() {});
    } catch (_) {
      _markVideoCompleted();
    }
  }

  void _handleVideoTick() {
    final controller = _videoController;
    if (controller == null) return;

    final value = controller.value;
    if (!value.isInitialized) return;

    if (value.duration > Duration.zero &&
        value.position >= value.duration &&
        !value.isPlaying) {
      _markVideoCompleted();
    }
  }

  void _handleAuthState(AuthState state) {
    if (state is AuthAuthenticated) {
      _pendingRoute = '/home';
    } else if (state is AuthUnauthenticated) {
      _pendingRoute = '/welcome';
    }

    _navigateIfReady();
  }

  void _markVideoCompleted() {
    if (_videoCompleted) return;

    _videoCompleted = true;
    _splashTimeout?.cancel();
    _navigateIfReady();

    if (mounted) {
      setState(() {});
    }
  }

  void _navigateIfReady() {
    final route = _pendingRoute;
    if (!_videoCompleted || route == null || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(route);
    });
  }

  @override
  void dispose() {
    _splashTimeout?.cancel();
    _videoController?.removeListener(_handleVideoTick);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;
    final showVideo = controller != null && controller.value.isInitialized;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) => _handleAuthState(state),
      child: Scaffold(
        body: showVideo
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note, size: 80, color: Colors.orange),
                    SizedBox(height: 20),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
      ),
    );
  }
}
