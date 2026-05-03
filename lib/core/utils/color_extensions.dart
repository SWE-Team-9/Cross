import 'package:flutter/painting.dart';

extension ColorWithValues on Color {
  /// Small helper to mimic a `withValues(alpha: ...)` API used across the
  /// codebase. Currently only supports `alpha` (opacity) which maps to
  /// `withOpacity`.
  Color withValues({double? alpha}) {
    if (alpha != null) return withOpacity(alpha);
    return this;
  }
}
