// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/deep_links/deep_link_destination.dart';
import '../bloc/auth_cubit.dart';
import '../routes/auth_routes.dart';

class OAuthDebugPage extends StatefulWidget {
  const OAuthDebugPage({
    super.key,
    required this.destination,
  });

  final OAuthCallbackDeepLink destination;

  @override
  State<OAuthDebugPage> createState() => _OAuthDebugPageState();
}

class _OAuthDebugPageState extends State<OAuthDebugPage> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthCubit>().handleOAuthCallbackDeepLink(widget.destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('OAuth Debugger'),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          }
        },
        builder: (context, state) {
          if (state is AuthOAuthDiagnostic) {
            return _DiagnosticView(state: state);
          }

          if (state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is AuthError) {
            return _FallbackErrorView(message: state.message);
          }

          return _InitialCallbackView(destination: widget.destination);
        },
      ),
    );
  }
}

class _InitialCallbackView extends StatelessWidget {
  const _InitialCallbackView({required this.destination});

  final OAuthCallbackDeepLink destination;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const Text(
            'Returned Callback',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _kv(
            'Code present',
            '${destination.code != null && destination.code!.isNotEmpty}',
          ),
          _kv('State', destination.state ?? 'null'),
          _kv('Error', destination.error ?? 'null'),
          _kv('Error description', destination.errorDescription ?? 'null'),
          const SizedBox(height: 24),
          const Text(
            'Processing OAuth callback...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticView extends StatelessWidget {
  const _DiagnosticView({required this.state});

  final AuthOAuthDiagnostic state;

  @override
  Widget build(BuildContext context) {
    final Color color = state.isError
        ? Colors.redAccent
        : state.isSuccess
            ? Colors.greenAccent
            : Colors.blueAccent;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Text(
            state.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Chip(
            label: Text(state.stage),
            backgroundColor: color.withValues(alpha: 0.18),
            labelStyle: TextStyle(color: color),
          ),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          if (state.details.isNotEmpty) ...[
            const Text(
              'Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...state.details.entries.map(
              (entry) => _kv(entry.key, entry.value),
            ),
          ],
          const SizedBox(height: 28),
          if (state.isError)
            ElevatedButton(
              onPressed: () => context.go(AuthRoutes.welcome),
              child: const Text('Back to Welcome'),
            ),
          if (state.isSuccess)
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Continue to Home'),
            ),
        ],
      ),
    );
  }
}

class _FallbackErrorView extends StatelessWidget {
  const _FallbackErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const Text(
            'OAuth Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AuthRoutes.welcome),
            child: const Text('Back to Welcome'),
          ),
        ],
      ),
    );
  }
}

Widget _kv(String key, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$key: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    ),
  );
}
