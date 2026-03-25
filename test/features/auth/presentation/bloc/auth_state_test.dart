import 'package:flutter_test/flutter_test.dart';

// Third-party
// Project
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';

void main() {
  // Single shared fixture — if User gains more required fields,
  // fix here only
  final tUser = User(
    id: 'user-uuid-123',
    email: 'ahmed@test.com',
    handle: 'ahmed-hassan-beats',
    displayName: 'Ahmed Hassan',
    isPro: false,
    isVerified: false,
  );

  group('AuthState', () {
    test('AuthInitial is AuthState',
        () => expect(AuthInitial(), isA<AuthState>()));

    test('AuthLoading is AuthState',
        () => expect(AuthLoading(), isA<AuthState>()));

    test('AuthUnauthenticated is AuthState',
        () => expect(AuthUnauthenticated(), isA<AuthState>()));

    group('AuthAuthenticated', () {
      test('holds the user object', () {
        final state = AuthAuthenticated(tUser);

        expect(state.user, tUser);
        expect(state.user.id, 'user-uuid-123');
        expect(state.user.handle, 'ahmed-hassan-beats');
      });

      test('props contains user', () {
        final state = AuthAuthenticated(tUser);

        expect(state.props, [tUser]);
      });
    });

    group('AuthRegisterSuccess', () {
      test('holds the user object', () {
        final state = AuthRegisterSuccess(tUser);

        expect(state.user, tUser);
        expect(state.user.email, 'ahmed@test.com');
      });
    });

    group('AuthProfileCompleted', () {
      test('holds the user object', () {
        final state = AuthProfileCompleted(tUser);

        expect(state.user, tUser);
        expect(state.user.displayName, 'Ahmed Hassan');
      });
    });

    group('AuthEmailCheckSuccess', () {
      test('holds exists true and email when account exists', () {
        final state = AuthEmailCheckSuccess(
          exists: true,
          email: 'ahmed@test.com',
        );

        expect(state.exists, true);
        expect(state.email, 'ahmed@test.com');
      });

      test('holds exists false when account does not exist', () {
        final state = AuthEmailCheckSuccess(
          exists: false,
          email: 'new@test.com',
        );

        expect(state.exists, false);
      });
    });

    group('AuthError', () {
      test('holds the error message', () {
        final state = AuthError('Something went wrong.');

        expect(state.message, 'Something went wrong.');
      });
    });

    group('AuthVerificationEmailSent', () {
      test('holds the email address', () {
        final state = AuthVerificationEmailSent('ahmed@test.com');

        expect(state.email, 'ahmed@test.com');
      });
    });

    group('AuthForgotPasswordSuccess', () {
      test('holds the email address', () {
        final state = AuthForgotPasswordSuccess('ahmed@test.com');

        expect(state.email, 'ahmed@test.com');
      });
    });

    test('AuthEmailVerified is AuthState',
        () => expect(AuthEmailVerified(), isA<AuthState>()));

    test('AuthResetPasswordSuccess is AuthState',
        () => expect(AuthResetPasswordSuccess(), isA<AuthState>()));
  });
}
