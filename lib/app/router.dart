import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injector.dart';
import '../features/upload/presentation/bloc/uploadPickerCubit.dart';
import '../features/upload/presentation/pages/UploadPickerPage.dart';

import '../features/auth/presentation/routes/auth_routes.dart';

class AppRoutes {
  static const String home = '/home';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Home Page',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

final GoRouter router = GoRouter(
  initialLocation: AuthRoutes.welcome,
  routes: [
    ...AuthRoutes.routes,
    GoRoute(
      path: AppRoutes.home,
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
