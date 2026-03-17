import 'package:go_router/go_router.dart';

import '../pages/auth_method_page.dart';
import '../pages/complete_profile_page.dart';
import '../pages/create_password_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/login_password_page.dart';
import '../pages/reset_password_page.dart';
import '../pages/verify_email_page.dart';
import '../pages/welcome_page.dart';

class AuthRoutes {
  static const String welcome = '/';
  static const String authMethod = '/auth-method';
  static const String loginPassword = '/login-password';
  static const String createPassword = '/create-password';
  static const String completeProfile = '/complete-profile';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';

  static final List<GoRoute> routes = [
    GoRoute(
      path: welcome,
      name: 'welcome',
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: authMethod,
      name: 'auth-method',
      builder: (context, state) => const AuthMethodPage(),
    ),
    GoRoute(
      path: loginPassword,
      name: 'login-password',
      builder: (context, state) {
        final email = state.extra as String;
        return LoginPasswordPage(email: email);
      },
    ),
    GoRoute(
      path: createPassword,
      name: 'create-password',
      builder: (context, state) {
        final email = state.extra as String;
        return CreatePasswordPage(email: email);
      },
    ),
    GoRoute(
      path: completeProfile,
      name: 'complete-profile',
      builder: (context, state) => const CompleteProfilePage(),
    ),
    GoRoute(
      path: forgotPassword,
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: resetPassword,
      name: 'reset-password',
      builder: (context, state) {
        final email = state.extra as String;
        return ResetPasswordPage(email: email);
      },
    ),
    GoRoute(
      path: verifyEmail,
      name: 'verify-email',
      builder: (context, state) {
        final email = state.extra as String;
        return VerifyEmailPage(email: email);
      },
    ),
  ];
}