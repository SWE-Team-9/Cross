# PR: AppNetworkImage Rollout (Phase 2)

## Date
2026-05-05

## Summary
Expanded shared cached image usage to additional high-traffic screens for faster track-cover rendering.

## Files Updated
- `lib/features/feed/presentation/widgets/feed_card.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/playlists/presentation/pages/playlist_detail_page.dart`

## What Changed
- Replaced selected `Image.network` usages with `AppNetworkImage`.
- Preserved existing visual fallbacks by mapping prior `errorBuilder` behavior into `errorWidget`.
- Kept dimensions, fit, and styling unchanged.

## Why
- Improve perceived speed and reduce repeated cover-image fetches.
- Standardize network image behavior with one reusable widget.

## Scope Notes
- This phase focused on the highest-impact surfaces requested: Feed, Home, and Playlist detail.
- Additional screens still use `Image.network` and can be migrated in a follow-up pass.
