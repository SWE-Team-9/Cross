import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_cubit.dart';
import '../routes/auth_routes.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';

class CreatePasswordPage extends StatefulWidget {
  final String email;

  const CreatePasswordPage({
    super.key,
    required this.email,
  });

  @override
  State<CreatePasswordPage> createState() => _CreatePasswordPageState();
}

class _CreatePasswordPageState extends State<CreatePasswordPage> {
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;

  final _formKey = GlobalKey<FormState>();

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _onContinuePressed() {
    if (!_formKey.currentState!.validate()) return;

    // تنبيه: بناءً على الـ API، دالة register قد تحتاج إلى إرسال الاسم وباقي البيانات هنا!
    context.read<AuthCubit>().register(
          email: widget.email,
          password: passwordController.text.trim(),
          passwordConfirm: confirmPasswordController.text.trim(),
          displayName: "New User", // قيمة افتراضية لتجنب خطأ الـ API حتى يتم إضافتها
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: AuthScreenWrapper(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthRegisterSuccess) {
                context.go(
                  AuthRoutes.verifyEmail,
                  extra: widget.email,
                );
              }

              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message, style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const AuthBackButton(),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Create an account',
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
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Password', style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            obscureText: isPasswordHidden,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Min. 8 characters',
                              hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                              filled: true,
                              fillColor: const Color(0xFF2C2C2E),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
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
                            validator: (value) {
                              final password = value?.trim() ?? '';
                              if (password.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (password.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Confirm Password', style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 16)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: isConfirmPasswordHidden,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Confirm password',
                              hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                              filled: true,
                              fillColor: const Color(0xFF2C2C2E),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isConfirmPasswordHidden = !isConfirmPasswordHidden;
                                  });
                                },
                                icon: Icon(
                                  isConfirmPasswordHidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF9B9B9B),
                                ),
                              ),
                            ),
                            validator: (value) {
                              final confirmPassword = value?.trim() ?? '';
                              if (confirmPassword.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (confirmPassword != passwordController.text.trim()) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          AuthButton(
                            text: 'Continue',
                            isLoading: isLoading,
                            onPressed: _onContinuePressed,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
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
                    ),
                    const SizedBox(height: 24),
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