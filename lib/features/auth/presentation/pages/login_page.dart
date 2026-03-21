import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';
import '../bloc/auth_cubit.dart';
import '../routes/auth_routes.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordHidden = true;
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
          "6LfFm5IsAAAAAA64uhxk_ee2zh7feA_H84M2gmps");
    } catch (e) {
      print("Failed to initialize Recaptcha: $e");
    }
  }

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
      if (_recaptchaClient == null) {
        _recaptchaClient = await Recaptcha.fetchClient(
            "6LfFm5IsAAAAAA64uhxk_ee2zh7feA_H84M2gmps");
      }

      String token = await _recaptchaClient!.execute(RecaptchaAction.LOGIN());

      if (mounted) {
        context.read<AuthCubit>().login(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              captchaToken: token,
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push(AuthRoutes.forgotPassword);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6D8FFF),
                          ),
                          child: const Text('Forgot password?',
                              style: TextStyle(fontSize: 16)),
                        ),
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
