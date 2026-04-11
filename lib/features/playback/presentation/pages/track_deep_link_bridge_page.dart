// playback/presentation/pages/track_deep_link_bridge_page.dart

// Flutter
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project — presentation
import '../bloc/track_loader_cubit.dart';
import '../bloc/track_loader_state.dart';
import '../bloc/player_cubit.dart';
import 'full_player_page.dart';

/// Shown while fetching track data triggered by a deep link.
///
/// Responsibilities:
///   - Show a loading spinner while [TrackLoaderCubit] fetches
///   - On [TrackLoaderReady] → navigate to [FullPlayerPage]
///   - On [TrackLoaderError] → show snackbar + navigate to Home
///
/// This page never talks to repositories, use cases, or Dio directly.
/// All logic lives in [TrackLoaderCubit].
class TrackDeepLinkBridgePage extends StatefulWidget {
  const TrackDeepLinkBridgePage({
    super.key,
    this.trackId,
    this.secretToken,
  }) : assert(
          trackId != null || secretToken != null,
          'Either trackId or secretToken must be provided.',
        );

  /// For soundclone://track/{trackId}
  final String? trackId;

  /// For soundclone://track/secret/{secretToken}
  final String? secretToken;

  @override
  State<TrackDeepLinkBridgePage> createState() =>
      _TrackDeepLinkBridgePageState();
}

class _TrackDeepLinkBridgePageState extends State<TrackDeepLinkBridgePage> {
  @override
  void initState() {
    super.initState();
    // Trigger load after first frame so context is available.
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
            // Replace bridge page with full player.
            // pushReplacement means back button won't return here.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: context.read<PlayerCubit>(),
                  child: const FullPlayerPage(),
                ),
              ),
            );

          case TrackLoaderError(:final message):
            // Show error then go home.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: const Color(0xFFFF5500),
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Clear navigation stack — back button goes to home, not bridge.
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (_) => false,
            );

          // Loading and idle are handled by the builder below.
          case TrackLoaderLoading():
          case TrackLoaderIdle():
            break;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<TrackLoaderCubit, TrackLoaderState>(
          builder: (context, state) {
            // Both idle and loading show the spinner —
            // idle is only visible for one frame before _load() fires.
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
