import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';

void main() {
  group('AuthRoutes Tests', () {
    test('route constants match the defined paths', () {
      // التحقق من المسارات الجديدة المحدثة
      expect(AuthRoutes.splash, '/'); // المسار الرئيسي الجديد
      expect(AuthRoutes.welcome, '/welcome'); // تم نقله من / إلى /welcome
      expect(AuthRoutes.login, '/login');
      expect(AuthRoutes.register, '/register');
      expect(AuthRoutes.completeProfile, '/complete-profile');
      expect(AuthRoutes.forgotPassword, '/forgot-password');
      expect(AuthRoutes.resetPassword, '/reset-password');
      expect(AuthRoutes.verifyEmail, '/verify-email');
    });

    test('routes list contains all defined GoRoutes', () {
      // التأكد من أن قائمة المسارات ليست فارغة وتحتوي على المسارات الأساسية
      expect(AuthRoutes.routes, isNotEmpty);

      final paths = AuthRoutes.routes.map((e) => e.path).toList();

      expect(paths, contains('/'));
      expect(paths, contains('/welcome'));
      expect(paths, contains('/login'));
      expect(paths, contains('/register'));
    });

    test('verifyEmail route expects extra data (email)', () {
      final verifyRoute =
          AuthRoutes.routes.firstWhere((r) => r.path == AuthRoutes.verifyEmail);
      expect(verifyRoute, isNotNull);
    });
  });
}
