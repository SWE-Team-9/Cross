import '../../../../core/errors/failure.dart';

sealed class NotificationsResult<T> {
  const NotificationsResult();

  const factory NotificationsResult.success(T value) = NotificationsSuccess<T>;

  const factory NotificationsResult.failure(Failure failure) =
      NotificationsFailure<T>;

  bool get isSuccess => this is NotificationsSuccess<T>;

  bool get isFailure => this is NotificationsFailure<T>;
}

final class NotificationsSuccess<T> extends NotificationsResult<T> {
  const NotificationsSuccess(this.value);

  final T value;

  @override
  String toString() => 'NotificationsResult.success($value)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationsSuccess<T> && other.value == value;
  }

  @override
  int get hashCode => Object.hash(NotificationsSuccess<T>, value);
}

final class NotificationsFailure<T> extends NotificationsResult<T> {
  const NotificationsFailure(this.failure);

  final Failure failure;

  @override
  String toString() => 'NotificationsResult.failure($failure)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationsFailure<T> && other.failure == failure;
  }

  @override
  int get hashCode => Object.hash(NotificationsFailure<T>, failure);
}
