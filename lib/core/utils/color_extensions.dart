import 'package:flutter/painting.dart';

extension ColorWithValues on Color {
  /// Small helper to mimic a `withValues(alpha: ...)` API used across the
  /// codebase. Currently only supports `alpha` (opacity) which maps to
  /// `withAlpha` to avoid using the deprecated `withOpacity` API.
  Color withValues({double? alpha}) {
    if (alpha != null) {
      final intAlpha = (alpha * 255).round().clamp(0, 255);
      return withAlpha(intAlpha);
    }
    return this;
  }
}
