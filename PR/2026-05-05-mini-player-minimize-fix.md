# PR: Mini Player Minimize Fix

## Date
2026-05-05

## Summary
Fixed the mini-player collapse behavior so minimizing the full player brings the mini-player back immediately instead of hiding it until a refresh or navigation change.

## Changes
- `closeFullPlayer()` now restores mini-player visibility in `PlayerCubit`.
- Added a route-path navigator observer so route changes stay in sync on push/pop/replace.
- Kept the mini-player overlay tied to the current route and player visibility state.

## Notes
- The issue was caused by state staying hidden after the full player was minimized.
- The route observer ensures back navigation updates the mini-player overlay without needing a manual refresh.
