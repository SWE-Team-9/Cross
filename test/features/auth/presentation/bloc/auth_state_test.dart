import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';

void main() {
  group('AuthState', () {
    const user = User(
      id: '1',
      email: 'test@example.com',
      displayName: 'Muslim',
    );

    test('AuthInitial can be created', () {
      expect(AuthInitial(), isA<AuthInitial>());
    });

    test('AuthLoading can be created', () {
      expect(AuthLoading(), isA<AuthLoading>());
    });

    test('AuthUnauthenticated can be created', () {
      expect(AuthUnauthenticated(), isA<AuthUnauthenticated>());
    });

    test('AuthAuthenticated stores user', () {
      final state = AuthAuthenticated(user);
      expect(state.user, user);
    });

    test('AuthRegisterSuccess stores user', () {
      final state = AuthRegisterSuccess(user);
      expect(state.user, user);
    });

    test('AuthProfileCompleted stores user', () {
      final state = AuthProfileCompleted(user);
      expect(state.user, user);
    });

    test('AuthEmailCheckSuccess stores exists and email', () {
      final state = AuthEmailCheckSuccess(
        exists: true,
        email: 'test@example.com',
      );

      expect(state.exists, true);
      expect(state.email, 'test@example.com');
    });

    test('AuthVerificationEmailSent stores email', () {
      final state = AuthVerificationEmailSent('test@example.com');
      expect(state.email, 'test@example.com');
    });

    test('AuthEmailVerified can be created', () {
      expect(AuthEmailVerified(), isA<AuthEmailVerified>());
    });

    test('AuthForgotPasswordSuccess stores email', () {
      final state = AuthForgotPasswordSuccess('test@example.com');
      expect(state.email, 'test@example.com');
    });

    test('AuthResetPasswordSuccess can be created', () {
      expect(AuthResetPasswordSuccess(), isA<AuthResetPasswordSuccess>());
    });

    test('AuthError stores message', () {
      final state = AuthError('Something went wrong');
      expect(state.message, 'Something went wrong');
    });
  });
}