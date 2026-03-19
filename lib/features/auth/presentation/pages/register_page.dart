import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_cubit.dart';
import '../routes/auth_routes.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_screen_wrapper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().register(
          displayName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          passwordConfirm: _confirmPasswordController.text.trim(),
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
                  extra: _emailController.text.trim(),
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
                      const AuthBackButton(),
                      const SizedBox(height: 32),
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
                      
                    
                      const Text('Display Name', style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 16)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Display name',
                          hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 20),

                      
                      const Text('Email address', style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 16)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'email@example.com',
                          hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your email' : null,
                      ),
                      const SizedBox(height: 20),

                      const Text('Password', style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 16)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordHidden,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Min. 8 characters',
                          hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: const Color(0xFF9B9B9B),
                            ),
                            onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a password';
                          if (value.length < 8) return 'Password must be at least 8 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      const Text('Confirm Password', style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 16)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _isConfirmPasswordHidden,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Re-enter your password',
                          hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: const Color(0xFF9B9B9B),
                            ),
                            onPressed: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please confirm your password';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      AuthButton(
                        text: 'Continue',
                        isLoading: isLoading,
                        onPressed: _onRegisterPressed,
                      ),
                      const SizedBox(height: 32),
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