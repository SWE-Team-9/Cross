import 'package:flutter/material.dart';

import '../../domain/entities/TrackManagementVisibility.dart';

class TrackVisibilitySelector extends StatelessWidget {
  const TrackVisibilitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final TrackManagementVisibility value;
  final ValueChanged<TrackManagementVisibility> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: TrackManagementVisibility.values.map((visibility) {
        return ChoiceChip(
          label: Text(visibility.displayLabel),
          selected: value == visibility,
          onSelected: enabled
              ? (selected) {
                  if (selected) {
                    onChanged(visibility);
                  }
                }
              : null,
        );
      }).toList(),
    );
  }
}
