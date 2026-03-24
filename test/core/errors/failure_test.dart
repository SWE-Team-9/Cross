import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';

void main() {
  group('Failure', () {
    test('ServerFailure stores message and toString returns it', () {
      const failure = ServerFailure('Server error');

      expect(failure.message, 'Server error');
      expect(failure.toString(), 'Server error');
      expect(failure, isA<Failure>());
      expect(failure, isA<Exception>());
    });

    test('NetworkFailure stores message', () {
      const failure = NetworkFailure('No internet connection.');

      expect(failure.message, 'No internet connection.');
      expect(failure.toString(), 'No internet connection.');
    });

    test('AuthFailure stores message', () {
      const failure = AuthFailure('Unauthorized');

      expect(failure.message, 'Unauthorized');
      expect(failure.toString(), 'Unauthorized');
    });

    test('ValidationFailure stores message', () {
      const failure = ValidationFailure('Invalid form');

      expect(failure.message, 'Invalid form');
      expect(failure.toString(), 'Invalid form');
    });

    test('NotFoundFailure stores message', () {
      const failure = NotFoundFailure('Not found');

      expect(failure.message, 'Not found');
      expect(failure.toString(), 'Not found');
    });

    test('ForbiddenFailure stores message', () {
      const failure = ForbiddenFailure('Forbidden');

      expect(failure.message, 'Forbidden');
      expect(failure.toString(), 'Forbidden');
    });
  });
}
