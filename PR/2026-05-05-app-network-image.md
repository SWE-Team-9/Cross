# PR: Shared Network Image Caching

## Date
2026-05-05

## Summary
Added a shared image widget to standardize network image behavior and improve perceived loading for track covers.

## Changes
- Added `lib/core/widgets/app_network_image.dart`.
- Migrated Discover reel background image loading from `Image.network` to `AppNetworkImage` in `lib/features/discovery/presentation/page/discover_page.dart`.

## Why
- `Image.network` usage across the app was inconsistent and did not provide uniform placeholder/error behavior.
- Discover covers are high-frequency and benefit immediately from cache-backed loading.

## Impact
- Better cache reuse for Discover cover images.
- Smoother UX with consistent fallback while images are loading or fail.

## Next Suggested Rollout
- Replace repeated `Image.network` usages in Feed, Home, Playlist, and Search result cards with `AppNetworkImage`.
- Optionally add size-aware cache hints for large lists/grids.
