import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';
import '../widgets/auth_text_field.dart';

class LoginPasswordPage extends StatefulWidget {
  final String email;

  const LoginPasswordPage({
    super.key,
    required this.email,
  });

  @override
  State<LoginPasswordPage> createState() => _LoginPasswordPageState();
}

class _LoginPasswordPageState extends State<LoginPasswordPage> {
  late final TextEditingController passwordController;
  bool isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  void _onContinuePressed() {
    final password = passwordController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    context.read<AuthCubit>().login(
          email: widget.email,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenWrapper(
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
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
                const Center(
                  child: Text(
                    'Log in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Your email address',
                  style: TextStyle(
                    color: Color(0xFF9B9B9B),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: passwordController,
                  hintText: 'Enter your password',
                  obscureText: isPasswordHidden,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        isPasswordHidden = !isPasswordHidden;
                      });
                    },
                    icon: Icon(
                      isPasswordHidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF9B9B9B),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AuthButton(
                  text: 'Continue',
                  isLoading: isLoading,
                  onPressed: _onContinuePressed,
                ),
                const SizedBox(height: 16),
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