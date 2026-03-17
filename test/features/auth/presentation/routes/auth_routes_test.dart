import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';

void main() {
  group('AuthRoutes', () {
    test('route constants are correct', () {
      expect(AuthRoutes.welcome, '/');
      expect(AuthRoutes.authMethod, '/auth-method');
      expect(AuthRoutes.loginPassword, '/login-password');
      expect(AuthRoutes.createPassword, '/create-password');
      expect(AuthRoutes.completeProfile, '/complete-profile');
      expect(AuthRoutes.forgotPassword, '/forgot-password');
      expect(AuthRoutes.resetPassword, '/reset-password');
      expect(AuthRoutes.verifyEmail, '/verify-email');
    });

    test('routes list is not empty', () {
      expect(AuthRoutes.routes, isNotEmpty);
    });
  });
}