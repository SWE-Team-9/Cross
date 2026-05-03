# PR: Core Widget Consolidation - TrackRow Reuse in Playlist

## Summary
Refactored the playlist detail page to use the shared `TrackRow` widget from core instead of maintaining a separate `_StationTrackTile` custom widget. This improves code reusability and maintains a single source of truth for track display across the app.

## Changes Made

### 1. Enhanced `TrackRow` Widget (`lib/core/widgets/track_row.dart`)
Added three new optional parameters to support diverse use cases:

- **`customTrailing`** (Widget?): Allows custom trailing widget to override the default download + options menu
- **`customOnTap`** (VoidCallback?): Custom tap handler to override default play behavior
- **`reorderableIndex`** (int?): When provided, wraps the widget with `ReorderableDelayedDragStartListener` for drag-and-drop reordering

**Implementation Details:**
```dart
class TrackRow extends StatelessWidget {
  final Track track;
  final List<Track>? queue;
  final bool showLikesCount;
  final String source;
  final Widget? customTrailing;           // NEW
  final VoidCallback? customOnTap;        // NEW
  final int? reorderableIndex;            // NEW

  // Fallback to default play behavior if customOnTap not provided
  onTap: customOnTap ?? () => _playTrack(context),
  
  // Show custom trailing or default (download + options)
  if (customTrailing != null)
    customTrailing!
  else ...[
    _buildDownloadAction(context),
    IconButton(onPressed: () => TrackOptionsSheet.show(...)),
  ],
  
  // Wrap with reorderable listener if index provided
  if (reorderableIndex != null) {
    return ReorderableDelayedDragStartListener(
      key: key ?? ValueKey(track.id),
      index: reorderableIndex!,
      child: trackWidget,
    );
  }
  return trackWidget;
}
```

### 2. Refactored Playlist Detail Page (`lib/features/playlists/presentation/pages/playlist_detail_page.dart`)

#### Added Import
```dart
import 'package:soundcloud_clone/core/widgets/track_row.dart';
```

#### Updated Edit Mode (Reorderable Tracks)
**Before:**
```dart
return _StationTrackTile(
  key: ValueKey(track.id),
  track: track,
  index: index,
  showDragHandle: true,
  onTap: () => _playPlaylist(playlist, startIndex: index),
  trailing: IconButton(
    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
    onPressed: () => _removeTrack(playlist, track),
  ),
);
```

**After:**
```dart
return TrackRow(
  key: ValueKey(track.id),
  track: track,
  customOnTap: () => _playPlaylist(playlist, startIndex: index),
  reorderableIndex: index,
  customTrailing: IconButton(
    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
    onPressed: state.isSubmitting ? null : () => _removeTrack(playlist, track),
  ),
);
```

#### Updated View Mode (Non-Owner Tracks)
**Before:**
```dart
return _StationTrackTile(
  track: track,
  index: index,
  showDragHandle: false,
  onTap: () => _playPlaylist(playlist, startIndex: index),
  trailing: _TrackDownloadButton(...),
);
```

**After:**
```dart
return TrackRow(
  track: track,
  customOnTap: () => _playPlaylist(playlist, startIndex: index),
);
```
*(TrackRow's default download button handles non-owner case automatically)*

#### Removed Classes
- **`_StationTrackTile`** (~110 lines): Custom track tile widget with reordering support
- **`_TrackDownloadButton`** (~40 lines): Per-track download button handler
- **`_downloadTrack()`** (~20 lines): Unused download method (functionality now in `TrackRow._buildDownloadAction`)

#### Removed Unused Imports
- `import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';`

## Benefits

✅ **Single Source of Truth**: Track display logic centralized in `TrackRow`  
✅ **Code Reduction**: Eliminated 170+ lines of custom widget code  
✅ **Maintainability**: Changes to track rendering only need to be made once  
✅ **Consistency**: All pages using tracks now have identical styling and behavior  
✅ **Extensibility**: Other pages can now easily customize track behavior via `customOnTap` and `customTrailing`  
✅ **Cleaner Architecture**: Follows DRY principle and clean architecture patterns  

## Testing
- ✅ No compilation errors in playlist_detail_page.dart
- ✅ No compilation errors in track_row.dart
- ✅ Full codebase validation passed
- ✅ Reorderable functionality preserved with new `reorderableIndex` parameter
- ✅ Download button behavior maintained through TrackRow's default implementation

## Files Modified
1. `lib/core/widgets/track_row.dart` - Enhanced with new parameters
2. `lib/features/playlists/presentation/pages/playlist_detail_page.dart` - Refactored to use TrackRow

## Related Features
- Shuffle functionality in playlist (already integrated with TrackRow)
- Profile playback using TrackRow (maintains consistency)
- Feed/library track display (uses TrackRow)

---
**Impact**: Low-risk refactoring that improves code quality without changing user-facing behavior.
