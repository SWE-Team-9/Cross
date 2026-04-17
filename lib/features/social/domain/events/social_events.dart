import 'dart:async';

class SocialEvents {
  SocialEvents._();

  static final StreamController<void> _followRefreshController =
      StreamController<void>.broadcast();

  static Stream<void> get followRefreshStream =>
      _followRefreshController.stream;

  static void emitFollowChanged() {
    if (_followRefreshController.isClosed) return;
    _followRefreshController.add(null);
  }
}
