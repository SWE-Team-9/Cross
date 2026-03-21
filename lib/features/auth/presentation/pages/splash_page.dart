import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // استدعاء دالة التحقق من حالة التسجيل الموجودة في الـ Cubit
    context.read<AuthCubit>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        print("Current Auth State: $state");
        if (state is AuthAuthenticated) {
          // إذا كان مسجل دخول، اذهب للهوم
          context.go('/home'); 
        } else if (state is AuthUnauthenticated) {
          // إذا لم يكن مسجل، اذهب لصفحة الـ Welcome
          context.go('/welcome');
        }
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // يمكنك تغيير الأيقونة بلوجو التطبيق الخاص بك
              Icon(Icons.music_note, size: 80, color: Colors.orange),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}