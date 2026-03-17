import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../routes/auth_routes.dart';
import '../bloc/auth_cubit.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthResetPasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset successfully')),
          );

          context.go(AuthRoutes.authMethod);
        }

        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reset Password'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Reset password for ${widget.email}',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthCubit>().resetPassword(
                                        email: widget.email,
                                        code: _codeController.text.trim(),
                                        newPassword:
                                            _passwordController.text.trim(),
                                      );
                                }
                              },
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Reset Password'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}