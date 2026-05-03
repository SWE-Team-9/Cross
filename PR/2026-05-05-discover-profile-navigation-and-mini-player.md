# PR: Discover Profile Navigation and Mini-Player Visibility

## Date
2026-05-05

## Summary
Fixed two remaining Discover-specific behaviors: artist/profile navigation now uses a direct route change, and the mini player is hidden again on the Discover screen.

## Changes
- Updated Discover artist taps to navigate directly to `/profile/{handle}` in `lib/features/discovery/presentation/page/discover_page.dart`.
- Restored Discover to the hidden mini-player route set in `lib/app/app.dart` using the shell-backed `/feed/discover` path.

## Why
- Artist taps from Discover were still feeling different from other navigation flows.
- Discover should remain a focused browsing surface without the mini player overlapping it.

## Impact
- Profile navigation from Discover should be more consistent.
- The mini player stays hidden while browsing Discover, but remains available again when leaving the page.
