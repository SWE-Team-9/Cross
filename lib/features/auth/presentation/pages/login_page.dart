// coverage:ignore-file
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';
//import 'package:webview_windows/webview_windows.dart';
import '../bloc/auth_cubit.dart';
import '../routes/auth_routes.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';
import '../../../../core/config/app_config.dart';

typedef LoginCaptchaTokenProvider = Future<String> Function(
  BuildContext context,
);

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.captchaTokenProvider,
  });

  final LoginCaptchaTokenProvider? captchaTokenProvider;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordHidden = true;
  bool _isFetchingCaptcha = false;
  bool _rememberMe = false;
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
      } catch (e) {}
    }
  }

  // Future<String> _getWindowsCaptchaToken(BuildContext context) async {
  //   final controller = WebviewController();
  //   final tokenCompleter = Completer<String>();

  //   await controller.initialize();

  //   controller.webMessage.listen((message) {
  //     final token = message.trim();

  //     if (!tokenCompleter.isCompleted && token.isNotEmpty) {
  //       tokenCompleter.complete(token);
  //     }
  //   });

  //   await controller.loadUrl(
  //     '${AppConfig.recaptchaWindowsWebUrl}/?action=login',
  //   );

  //   if (!context.mounted) {
  //     throw Exception('Context is no longer mounted.');
  //   }

  //   bool dialogClosed = false;

  //   Future<void> closeDialogIfNeeded() async {
  //     if (dialogClosed || !context.mounted) return;
  //     dialogClosed = true;
  //     Navigator.of(context, rootNavigator: true).pop();
  //   }

  //   final dialogFuture = showDialog<void>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) {
  //       return AlertDialog(
  //         backgroundColor: const Color(0xFF111111),
  //         title: const Text(
  //           'Security verification',
  //           style: TextStyle(color: Colors.white),
  //         ),
  //         content: SizedBox(
  //           width: 500,
  //           height: 650,
  //           child: Column(
  //             children: [
  //               const Padding(
  //                 padding: EdgeInsets.only(bottom: 12),
  //                 child: Text(
  //                   'Please complete the verification.',
  //                   style: TextStyle(color: Colors.white70),
  //                 ),
  //               ),
  //               const Divider(color: Color(0xFF2A2A2A), height: 1),
  //               const SizedBox(height: 12),
  //               Expanded(
  //                 child: ClipRRect(
  //                   borderRadius: BorderRadius.circular(12),
  //                   child: Webview(controller),
  //                 ),
  //               ),
  //               const SizedBox(height: 12),
  //               Align(
  //                 alignment: Alignment.centerRight,
  //                 child: TextButton(
  //                   onPressed: () {
  //                     if (!tokenCompleter.isCompleted) {
  //                       tokenCompleter.completeError(
  //                         Exception('Captcha verification was cancelled.'),
  //                       );
  //                     }
  //                     Navigator.of(dialogContext).pop();
  //                   },
  //                   child: const Text('Cancel'),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );

  //   try {
  //     final token = await tokenCompleter.future.timeout(
  //       const Duration(seconds: 90),
  //       onTimeout: () {
  //         throw TimeoutException('Captcha verification timed out.');
  //       },
  //     );

  //     await closeDialogIfNeeded();
  //     await dialogFuture;
  //     return token;
  //   } catch (e) {
  //     await closeDialogIfNeeded();
  //     await dialogFuture;
  //     rethrow;
  //   }
  // }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isFetchingCaptcha = true;
    });

    try {
      String token = "";

      if (Platform.isWindows) {
        // Captcha is disabled on backend for Windows.
        // Do not open verification dialog.
        token = "";
      } else if (widget.captchaTokenProvider != null) {
        token = await widget.captchaTokenProvider!(context);
      } else if (Platform.isAndroid || Platform.isIOS) {
        if (_recaptchaClient == null) {
          _recaptchaClient =
              await Recaptcha.fetchClient(AppConfig.recaptchaAndroidSiteKey);
        }
        token = await _recaptchaClient!.execute(RecaptchaAction.LOGIN());
      }

      if (mounted) {
        context.read<AuthCubit>().login(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              captchaToken: token,
              rememberMe: _rememberMe,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Security verification failed. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
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
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                context.go('/home');
              }
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message,
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 5),
                    action: state.isNotVerified
                        ? SnackBarAction(
                            label: 'Verify Now',
                            textColor: Colors.white,
                            onPressed: () {
                              context.push(AuthRoutes.verifyEmail,
                                  extra: _emailController.text.trim());
                            },
                          )
                        : null,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = (state is AuthLoading) || _isFetchingCaptcha;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const AuthBackButton(),
                      const SizedBox(height: 32),
                      const Center(
                        child: Text(
                          'Log in to your account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Email address',
                        style:
                            TextStyle(color: Color(0xFF9B9B9B), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your email'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Password',
                        style:
                            TextStyle(color: Color(0xFF9B9B9B), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordHidden,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordHidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF9B9B9B),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your password'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor:
                                      const Color(0xFF555555),
                                ),
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: Colors.white,
                                  checkColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              context.push(AuthRoutes.forgotPassword);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6D8FFF),
                            ),
                            child: const Text('Forgot password?',
                                style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      AuthButton(
                        text: 'Log in',
                        isLoading: isLoading,
                        onPressed: _onLoginPressed,
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          "Protected by reCAPTCHA Enterprise",
                          style:
                              TextStyle(color: Color(0xFF555555), fontSize: 12),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
