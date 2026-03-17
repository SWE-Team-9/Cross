import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../bloc/auth_cubit.dart';
import '../routes/auth_routes.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';
import '../widgets/social_auth_button.dart';

class AuthMethodPage extends StatefulWidget {
  const AuthMethodPage({super.key});

  @override
  State<AuthMethodPage> createState() => _AuthMethodPageState();
}

class _AuthMethodPageState extends State<AuthMethodPage> {
  late final TextEditingController emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _continueWithEmail() {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    context.read<AuthCubit>().checkEmail(email: email);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenWrapper(
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthEmailCheckSuccess) {
            if (state.exists) {
              context.push(AuthRoutes.loginPassword, extra: state.email);
            } else {
              context.push(AuthRoutes.createPassword, extra: state.email);
            }
          }

          if (state is AuthAuthenticated) {
            context.go(AppRoutes.home);
          }

          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const AuthBackButton(),
                const SizedBox(height: 24),
                const Text(
                  'Sign in or create an account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 22),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: Color(0xFF9B9B9B),
                      fontSize: 17,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'By clicking on any of the “Continue” buttons below, you agree to SoundCloud’s ',
                      ),
                      TextSpan(
                        text: 'Terms of Use',
                        style: TextStyle(color: Color(0xFF6D8FFF)),
                      ),
                      TextSpan(text: ' and acknowledge our '),
                      TextSpan(
                        text: 'Privacy Policy.',
                        style: TextStyle(color: Color(0xFF6D8FFF)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SocialAuthButton(
                  text: 'Continue with Facebook',
                  backgroundColor: const Color(0xFF1452D7),
                  textColor: Colors.white,
                  leading: const Icon(Icons.facebook, color: Colors.white),
                  onPressed: () {},
                ),
                const SizedBox(height: 14),
                SocialAuthButton(
                  text: 'Continue with Google',
                  backgroundColor: const Color(0xFF2E2E2E),
                  textColor: Colors.white,
                  leading: const Icon(Icons.g_mobiledata, color: Colors.white),
                  onPressed: () {},
                ),
                const SizedBox(height: 14),
                SocialAuthButton(
                  text: 'Continue with Apple',
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  leading: const Icon(Icons.apple, color: Colors.white),
                  onPressed: () {},
                ),
                const SizedBox(height: 26),
                const Text(
                  'Or with email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Your email address or profile URL',
                          hintStyle: const TextStyle(
                            color: Color(0xFF8B8B8B),
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4C4C4E),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4C4C4E),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6D8FFF),
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Please enter your email';
                          }

                          final emailRegex =
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(email)) {
                            return 'Please enter a valid email';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4C4C4E),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'CAPTCHA placeholder',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthButton(
                        text: 'Continue',
                        isLoading: isLoading,
                        onPressed: _continueWithEmail,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: const Color(0xFF6D8FFF),
                  ),
                  child: const Text(
                    'Need help?',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}