import 'package:go_router/go_router.dart';
import '../pages/complete_profile_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/reset_password_page.dart';
import '../pages/verify_email_page.dart';
import '../pages/welcome_page.dart';
import '../pages/splash_page.dart'; // إضافة الـ Splash

class AuthRoutes {
  static const String splash = '/'; // جعل الـ Splash هو المسار الرئيسي
  static const String welcome = '/welcome'; // تغيير مسار الـ welcome
  static const String login = '/login';
  static const String register = '/register';
  static const String completeProfile = '/complete-profile';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';

  static final List<GoRoute> routes = [
    GoRoute(
      path: splash,
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: welcome,
      name: 'welcome',
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: login,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: register,
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    // ... باقي الـ routes كما هي في كودك الأصلي
    GoRoute(
      path: completeProfile,
      name: 'complete-profile',
      builder: (context, state) {
        final data = state.extra as Map<String, String>;
        return CompleteProfilePage(registrationData: data);
      },
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