import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../bloc/auth_cubit.dart';
import '../../../../core/widgets/update_dialog.dart';

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
  bool _updateCheckDone =
      false; // ADD: track if update check (and dialog) is complete

  bool _isRunningInWidgetTest() {
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return bindingType.contains('TestWidgetsFlutterBinding') ||
        bindingType.contains('AutomatedTestWidgetsFlutterBinding') ||
        bindingType.contains('LiveTestWidgetsFlutterBinding');
  }

  @override
  void initState() {
    super.initState();

    _splashTimeout = Timer(const Duration(seconds: 8), _markVideoCompleted);
    context.read<AuthCubit>().checkAuthStatus();
    _initializeSplashVideo();

    // Skip update checks in widget tests to avoid pending timer/network side effects.
    if (!_isRunningInWidgetTest()) {
      _checkForUpdate();
    } else {
      _updateCheckDone = true; // skip in tests
    }
  }

  Future<void> _checkForUpdate() async {
    final result = await UpdateService.checkForUpdate();

    if (result != null && mounted) {
      final packageInfo = await PackageInfo.fromPlatform();
      final mandatory = UpdateService.isMandatoryUpdate(
        result.data,
        packageInfo.version,
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: !mandatory,
        builder: (_) => UpdateDialog(
          updateData: result.data,
          downloadUrl: result.downloadUrl,
          updateType: result.updateType,
          isMandatory: mandatory,
        ),
      );
    }

    if (mounted) {
      setState(() => _updateCheckDone = true);
      _navigateIfReady();
    }
  }

  Future<void> _initializeSplashVideo() async {
    try {
      final controller = VideoPlayerController.asset('assets/videos/splash.mp4');
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
    // ADD: require update check to be done as well
    if (!_videoCompleted || !_updateCheckDone || route == null || !mounted)
      return;

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
