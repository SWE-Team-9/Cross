import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/failure.dart';

part 'notifications_result.freezed.dart';

@freezed
class NotificationsResult<T> with _$NotificationsResult<T> {
  const factory NotificationsResult.success(T value) = NotificationsSuccess<T>;
  const factory NotificationsResult.failure(Failure failure) =
      NotificationsFailure<T>;
}
