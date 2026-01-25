# NavigationBuilder Group Mismatch Bug

> **Last Updated**: January 24, 2026
> **Status**: Fixed and Verified ✓
> **Severity**: Critical (app crash)
> **Platform**: macOS (desktop), potentially other desktop platforms
> **Verified**: App successfully runs on macOS after fix

---

## Summary

A null check crash occurred in `NavigationBuilder.build()` on macOS due to a mismatch between `DefaultRoute.group` and `NavigationData.group`. The bug manifested only on desktop platforms (macOS), not on web, due to differences in platform initialization timing.

---

## The Bug

### Location
`NavigationUtils/lib/src/navigation_builder.dart`, line 235 (before fix):

```dart
// BEFORE (crashes):
if (i < lastGroupIndex[groupName]!) {
  continue;
}
```

### Error Message
```
Null check operator used on a null value
```

---

## Root Cause Analysis

### Code Flow in NavigationBuilder.build()

The `build()` method uses a two-pass algorithm to handle route grouping:

#### First Pass (lines 195-213)
Iterates through `routeDataList` and builds a `lastGroupIndex` map using `route.group`:

```dart
for (int i = 0; i < routeDataList.length; i++) {
  Object route = routeDataList[i];
  if (route is DefaultRoute && route.group != null) {
    String groupName = route.group!;  // <-- Uses route.group
    lastGroupIndex[groupName] = i;
  }
}
```

**Key point**: The first pass only tracks groups when `route.group` is not null.

#### Second Pass (lines 216-345)
Iterates again and looks up `NavigationData` from the route configuration, then uses `navigationData.group`:

```dart
NavigationData? navigationData = NavigationUtils.getNavigationDataFromRoute(
    routes: routes, route: route);

if (navigationData.group != null) {
  String groupName = navigationData.group!;  // <-- Uses navigationData.group
  final lastIndex = lastGroupIndex[groupName];  // <-- May not exist!
}
```

**Key point**: The second pass uses `navigationData.group`, which may differ from `route.group`.

### The Mismatch

| Source | Property | Origin |
|--------|----------|--------|
| `DefaultRoute.group` | `route.group` | Set when route is created (push, fromUrl, etc.) |
| `NavigationData.group` | `navigationData.group` | Defined in app's navigation configuration |

#### How Routes Get Their Group Property

In `NavigationUtils.mapNavigationDataToDefaultRoute()` (utils.dart:133-139):

```dart
routeHolder = DefaultRoute(
    label: navigationDataHolder.label ?? '',
    path: path,
    pathParameters: pathParameters,
    queryParameters: route.queryParameters,
    group: navigationDataHolder.group,  // <-- Group IS COPIED from NavigationData
    metadata: navigationDataHolder.metadata);
```

**However**, routes can also be created:
- Directly via `DefaultRoute.fromUrl()` without NavigationData lookup
- Via `DefaultRoute()` constructor with no group specified
- From URL parsing without going through the mapping function

### When the Mismatch Occurs

```
Scenario:
1. Route created from URL: DefaultRoute.fromUrl('/games')
   → route.group = null (not specified)

2. NavigationData for '/games' has: group: 'HomePage'
   → navigationData.group = 'HomePage'

3. First pass: route.group is null, no entry in lastGroupIndex

4. Second pass: navigationData.group = 'HomePage'
   → lastGroupIndex['HomePage'] doesn't exist!
   → lastGroupIndex['HomePage']! causes NULL CHECK CRASH
```

---

## Why Web Works But macOS Crashes

### Platform Initialization Differences

#### On Web (works):
- Flutter's initialization is more synchronous
- Routes typically go through `setNewRoutePath()` which calls `mapNavigationDataToDefaultRoute()`
- The mapping function properly copies `navigationData.group` to `route.group`
- Both passes use the same group value

#### On macOS/Desktop (crashes):
- Platform initialization may happen differently:
  - System deep links parsed directly
  - App state restoration bypasses mapping
  - URL parsing happens before navigation setup is complete

#### The Critical Path in `setNewRoutePath()` (navigation_delegate.dart:281-297):

```dart
NavigationData? navigationData = NavigationUtils.getNavigationDataFromRoute(
    routes: navigationDataRoutes, route: configuration);

// Resolve Route From Navigation Data.
DefaultRoute? configurationHolder =
    NavigationUtils.mapNavigationDataToDefaultRoute(
        route: configuration,
        routes: navigationDataRoutes,
        globalData: globalData,
        navigationData: navigationData);

// Unknown route. Show unknown route.
configurationHolder ??= configuration;  // <-- FALLS BACK TO ORIGINAL if mapping fails
```

**Problem**: If `mapNavigationDataToDefaultRoute()` returns `null`, the original `configuration` (which may have `group: null`) is used.

### Timing Diagram

```
WEB FLOW (works):
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Browser URL     │───▶│ setNewRoutePath  │───▶│ mapNavigation   │
│ Change          │    │                  │    │ DataToDefault   │
└─────────────────┘    └──────────────────┘    │ Route           │
                                               │ group: copied ✓ │
                                               └─────────────────┘

MACOS FLOW (crashed):
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Deep Link /     │───▶│ DefaultRoute     │───▶│ build() called  │
│ App Restore     │    │ .fromUrl()       │    │ route.group=null│
└─────────────────┘    │ group: null ✗    │    │ navData.group=X │
                       └──────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                               ┌─────────────────┐
                                               │ lastGroupIndex  │
                                               │ [X] doesn't     │
                                               │ exist → CRASH   │
                                               └─────────────────┘
```

---

## The Fix

### Root Cause Fix (Recommended)

The root cause fix is to use the same source of truth in both passes. Changed the second pass to use `route.group` instead of `navigationData.group`:

```dart
// BEFORE (inconsistent sources):
// First pass:  uses route.group
// Second pass: uses navigationData.group  <-- MISMATCH!

// AFTER (consistent source):
// First pass:  uses route.group
// Second pass: uses route.group  ✓

if (route.group != null) {  // Changed from navigationData.group
  String groupName = route.group!;

  final lastIndex = lastGroupIndex[groupName];
  if (lastIndex != null && i < lastIndex) {
    continue;
  }
  // ...
}
```

### Location
`NavigationUtils/lib/src/navigation_builder.dart`, lines 226-244

### Why This Works

1. **Consistency**: Both passes now use the same source (`route.group`)
2. **Correct behavior**: If routes are created properly through `mapNavigationDataToDefaultRoute()`, `route.group` already equals `navigationData.group`
3. **Graceful degradation**: If `route.group` is null (route wasn't created properly), we don't apply group logic rather than crashing
4. The null-safe access on `lastIndex` provides additional safety

---

## Related Files

| File | Role |
|------|------|
| `lib/src/navigation_builder.dart` | Contains the bug and fix (line 234-237) |
| `lib/src/navigation_delegate.dart` | `BaseRouterDelegate` manages routes, `DefaultRoute` class definition |
| `lib/src/utils.dart` | `NavigationUtils.getNavigationDataFromRoute()` and `mapNavigationDataToDefaultRoute()` |

---

## Testing

To verify the fix works:

1. **Web**: Run `flutter run -d chrome` - should work (always worked)
2. **macOS**: Run `flutter run -d macos` - should now work (previously crashed)
3. **Windows**: Run `flutter run -d windows` - test to ensure no regression

### Edge Cases to Test

1. Routes with `group` property set in NavigationData but created via `DefaultRoute.fromUrl()`
2. Deep links that map to grouped routes
3. App state restoration with grouped routes
4. Tab navigation with grouped pages

---

## Recommendations

### Short-term (implemented)
Use null-safe access when looking up group indices.

### Long-term Considerations

1. **Ensure consistent group assignment**: When creating routes from URLs, always go through `mapNavigationDataToDefaultRoute()` to ensure proper group assignment.

2. **Add validation**: Consider adding debug assertions to catch group mismatches early:
   ```dart
   assert(route.group == navigationData?.group || route.group == null,
       'Route group mismatch: route.group=${route.group}, navigationData.group=${navigationData?.group}');
   ```

3. **Defensive first pass**: Consider modifying the first pass to also check NavigationData:
   ```dart
   NavigationData? navData = NavigationUtils.getNavigationDataFromRoute(
       routes: routes, route: route);
   String? groupName = route.group ?? navData?.group;
   ```

---

## Appendix: Route Group Feature

### Purpose

Route grouping allows multiple URLs to be treated as the same logical page. This is useful for:

- Tab navigation (different tabs, same shell widget)
- Nested navigation (sub-routes within a parent)
- Preventing duplicate page instances

### Example

```dart
// Home, Games, Apps tabs all use the same HomePage widget
NavigationData(
  label: 'GamesPage',
  url: '/games',
  builder: (context, routeData, globalData) => const HomePage(tab: 'games'),
  group: 'HomePage',  // <-- All tabs share this group
),
NavigationData(
  label: 'AppsPage',
  url: '/apps',
  builder: (context, routeData, globalData) => const HomePage(tab: 'apps'),
  group: 'HomePage',  // <-- Same group prevents stacking
),
```

---

*This document is part of the NavigationUtils library documentation.*
