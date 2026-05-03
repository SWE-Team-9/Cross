abstract class Failure implements Exception {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

/// 500, unexpected server errors
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again.']);
}

/// No internet / connection timeout
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// 401 — token expired or not logged in
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Session expired. Please log in again.']);
}

/// 403 — logged in but no permission
class ForbiddenFailure extends Failure {
  const ForbiddenFailure(
      [super.message = 'You don\'t have permission to do this.']);
}

/// 404
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

/// 422 / bad input
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input.']);
}

/// Generic catch-all
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
