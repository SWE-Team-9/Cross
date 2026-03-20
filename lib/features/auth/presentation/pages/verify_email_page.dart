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
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onVerifyPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().verifyEmail(
            code: _codeController.text.trim(), 
          );
    }
  }

  void _onResendPressed() {
    context.read<AuthCubit>().sendEmailVerification(
          email: widget.email,
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
              if (state is AuthEmailVerified) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email verified successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                context.go(AuthRoutes.completeProfile); 
              }

              if (state is AuthVerificationEmailSent) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification email sent again'),
                    backgroundColor: Colors.blueAccent,
                  ),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () {
                            context.go(AuthRoutes.register);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Center(
                        child: Text(
                          'Verify Email',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Enter the verification code sent to:\n${widget.email}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF9B9B9B),
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      const Text(
                        'Verification Code',
                        style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _codeController,
                        style: const TextStyle(color: Colors.white, letterSpacing: 2.0),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Enter code',
                          hintStyle: const TextStyle(color: Color(0xFF8B8B8B), letterSpacing: 0),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      AuthButton(
                        text: 'Verify Email',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _onVerifyPressed,
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: TextButton(
                          onPressed: isLoading ? null : _onResendPressed,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6D8FFF),
                          ),
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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