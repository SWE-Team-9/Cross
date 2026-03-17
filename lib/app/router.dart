import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injector.dart';
import '../features/upload/presentation/bloc/uploadPickerCubit.dart';
import '../features/upload/presentation/pages/UploadPickerPage.dart';

// Temporary placeholder widgets until real pages are created
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Login Page - Placeholder'),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Page - Placeholder'),
      ),
    );
  }
}

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/upload-picker',
      name: 'upload-picker',
      builder: (context, state) => BlocProvider<UploadPickerCubit>(
        create: (_) => getIt<UploadPickerCubit>(),
        child: const UploadPickerPage(),
      ),
    ),
  ],
);
