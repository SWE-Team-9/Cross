import 'failure.dart';

/// Maps domain failures to safe, user-facing messages.
class FailureMessageMapper {
  static String toUserMessage(
    Failure failure, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    return switch (failure) {
      NetworkFailure() => 'No internet connection. Please try again.',
      AuthFailure() => 'Please sign in and try again.',
      ForbiddenFailure() => 'You do not have permission to do this action.',
      NotFoundFailure() => 'The requested data could not be found.',
      ValidationFailure() => 'The request is invalid. Please review and try again.',
      ServerFailure() => fallback,
      _ => fallback,
    };
  }
}