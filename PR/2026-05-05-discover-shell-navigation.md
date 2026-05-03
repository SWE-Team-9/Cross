# PR: Discover Shell Navigation Fix

## Date
2026-05-05

## Summary
Moved Discover into the main shell navigation flow so it behaves like the rest of the tab pages when using the bottom navigation bar.

## Changes
- Added Discover as a nested route under the feed shell branch in `lib/app/router.dart`.
- Kept `/discover` as a redirect alias to preserve compatibility.
- Removed Discover's custom bottom navigation bar from `lib/features/discovery/presentation/page/discover_page.dart`.
- Stopped treating Discover as a hidden mini-player route in `lib/app/app.dart`.
- Updated Feed's Discover entry point to navigate directly to the shell-backed route.

## Why
- Discover had its own navigation flow, which made transitions out of it feel different from the main tab pages.
- Shell-backed navigation keeps bottom-nav behavior consistent and preserves branch state better.

## Impact
- Discover now uses the same shell flow as Home, Feed, Search, Library, and Upgrade.
- Navigation from Discover to other tabs should feel consistent with the rest of the app.
