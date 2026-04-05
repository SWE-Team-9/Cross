import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';
import 'package:webview_windows/webview_windows.dart';

import '../routes/auth_routes.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';
import '../widgets/auth_text_field.dart';
import '../../../../core/config/app_config.dart';

typedef RegisterCaptchaTokenProvider = Future<String> Function(
  BuildContext context,
);

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    this.captchaTokenProvider,
  });

  final RegisterCaptchaTokenProvider? captchaTokenProvider;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isFetchingCaptcha = false;
  RecaptchaClient? _recaptchaClient;

  @override
  void initState() {
    super.initState();
    _initRecaptcha();
  }

  void _initRecaptcha() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        _recaptchaClient =
            await Recaptcha.fetchClient(AppConfig.recaptchaAndroidSiteKey);
      } catch (e) {
        print("Failed to initialize Recaptcha: $e");
      }
    }
  }

  Future<String> _getWindowsCaptchaToken(BuildContext context) async {
    final controller = WebviewController();
    final tokenCompleter = Completer<String>();

    await controller.initialize();

    controller.webMessage.listen((message) {
      final token = message.trim();

      if (!tokenCompleter.isCompleted && token.isNotEmpty) {
        tokenCompleter.complete(token);
      }
    });

    await controller.loadUrl(
      '${AppConfig.recaptchaWindowsWebUrl}/?action=signup',
    );

    if (!context.mounted) {
      throw Exception('Context is no longer mounted.');
    }

    bool dialogClosed = false;

    Future<void> closeDialogIfNeeded() async {
      if (dialogClosed || !context.mounted) return;
      dialogClosed = true;
      Navigator.of(context, rootNavigator: true).pop();
    }

    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Security verification',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 500,
            height: 650,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Please complete the verification.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Webview(controller),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      if (!tokenCompleter.isCompleted) {
                        tokenCompleter.completeError(
                          Exception('Captcha verification was cancelled.'),
                        );
                      }
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final token = await tokenCompleter.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw TimeoutException('Captcha verification timed out.');
        },
      );

      await closeDialogIfNeeded();
      await dialogFuture;
      return token;
    } catch (e) {
      await closeDialogIfNeeded();
      await dialogFuture;
      rethrow;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onNextPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isFetchingCaptcha = true;
    });

    try {
      String token = "";

      if (widget.captchaTokenProvider != null) {
        token = await widget.captchaTokenProvider!(context);
      } else {
        if (Platform.isAndroid || Platform.isIOS) {
          if (_recaptchaClient == null) {
            _recaptchaClient =
                await Recaptcha.fetchClient(AppConfig.recaptchaAndroidSiteKey);
          }
          token =
              await _recaptchaClient!.execute(RecaptchaAction.custom('signup'));
        } else if (Platform.isWindows) {
          token = await _getWindowsCaptchaToken(context);
        }
      }

      if (token.isNotEmpty && mounted) {
        context.push(
          AuthRoutes.completeProfile,
          extra: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'passwordConfirm': _confirmPasswordController.text.trim(),
            'captchaToken': token,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security verification failed. Please try again.',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCaptcha = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: AuthScreenWrapper(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const AuthBackButton(),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Create account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "What's your email?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _emailController,
                    hintText: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Create a password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!RegExp(
                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$')
                          .hasMatch(value)) {
                        return 'Requires upper/lowercase, number & special char';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Confirm your password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm password',
                    isPassword: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  AuthButton(
                    text: 'Next',
                    isLoading: _isFetchingCaptcha,
                    onPressed: _onNextPressed,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "Protected by reCAPTCHA Enterprise",
                      style: TextStyle(color: Color(0xFF555555), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Color(0xFF9B9B9B)),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AuthRoutes.login),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
