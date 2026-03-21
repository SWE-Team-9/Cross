import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';

import '../routes/auth_routes.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

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
    try {
      _recaptchaClient = await Recaptcha.fetchClient(
          "6LcPd5EsAAAAAO8YOCSJJJr3PmX_lBzPaF-SvxR7");
    } catch (e) {
      print("Failed to initialize Recaptcha: $e");
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
      if (_recaptchaClient == null) {
        // 🔴 حط الـ Site Key بتاعك هنا برضه
        _recaptchaClient = await Recaptcha.fetchClient(
            "6LcPd5EsAAAAAO8YOCSJJJr3PmX_lBzPaF-SvxR7");
      }

      // 🟢 جلب التوكن في صمت (Invisible) 🟢
      String token =
          await _recaptchaClient!.execute(RecaptchaAction.custom('signup'));

      if (mounted) {
        context.push(
          AuthRoutes.completeProfile,
          extra: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'passwordConfirm': _confirmPasswordController.text.trim(),
            'captchaToken': token, // 👈 هنبعت التوكن لصفحة تكملة البيانات
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
                    isLoading:
                        _isFetchingCaptcha, // 👈 الزرار بيلف وهو بيجيب التوكن
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
