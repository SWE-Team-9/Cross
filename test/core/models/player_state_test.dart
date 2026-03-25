import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';

void main() {
  test('PlayerState copyWith updates fields correctly', () {
    const state = PlayerState(
      status: PlayerStatus.idle,
      position: Duration.zero,
      duration: null,
    );

    final updated = state.copyWith(
      status: PlayerStatus.playing,
      position: const Duration(seconds: 10),
    );

    expect(updated.status, PlayerStatus.playing);
    expect(updated.position, const Duration(seconds: 10));
  });

  test('PlayerState equality works correctly', () {
    const a = PlayerState(
      status: PlayerStatus.paused,
      position: Duration(seconds: 5),
      duration: Duration(minutes: 3),
    );

    const b = PlayerState(
      status: PlayerStatus.paused,
      position: Duration(seconds: 5),
      duration: Duration(minutes: 3),
    );

    expect(a, equals(b));
  });
}
