import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_cubit.dart';
import '../routes/auth_routes.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;

  const VerifyEmailPage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _timer;
  int _start = 0;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  void _initializeTimer() {
    final cubit = context.read<AuthCubit>();
    final remaining = cubit.remainingResendSeconds;

    if (remaining > 0) {
      // User returned while cooldown is still active
      _start = remaining;
      _startTimer();
    } else {
      // No active cooldown, trigger auto-send and start 60s timer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cubit.sendEmailVerification(email: widget.email);
        _start = 60;
        _startTimer();
      });
    }
  }

  void _startTimer() {
    setState(() => _canResend = false);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start <= 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onResendPressed() {
    if (_canResend) {
      context.read<AuthCubit>().sendEmailVerification(email: widget.email);
      _start = 60; // Reset countdown for UI
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: AuthScreenWrapper(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthVerificationEmailSent) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('A verification link has been sent to your email.'),
                    backgroundColor: Colors.blueAccent,
                  ),
                );
              }
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
                );
              }
              if (state is AuthUnauthenticated) {
                context.go(AuthRoutes.login);
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mark_email_unread_rounded, size: 100, color: Color(0xFF6D8FFF)),
                    const SizedBox(height: 32),
                    const Text('Check Your Email', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Text('We have sent a verification link to:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(widget.email, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    const Text('Please click on the link in the email to verify your account. Once verified, return here to log in.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 14, height: 1.5)),
                    const SizedBox(height: 48),
                    AuthButton(
                      text: 'Go to Login',
                      onPressed: () => context.read<AuthCubit>().logout(),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _canResend && !isLoading ? _onResendPressed : null,
                      child: Text(
                        _canResend ? 'Resend Link' : 'Resend link in $_start s',
                        style: TextStyle(
                          color: _canResend ? const Color(0xFF6D8FFF) : Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}