# Navigation Utils - Cache Behavior Analysis

## Date: October 28, 2025

## Current Cache Behavior Summary

### How Cache Keys Are Generated

The cache key generation happens in `NavigationBuilder.generateCacheKey()`:

```dart
static String generateCacheKey(NavigationData navigationData, DefaultRoute route) {
  // 1. If route already has a cacheKey, return it
  if (route.cacheKey != null) return route.cacheKey!;
  
  // 2. For grouped routes, use the group name
  if (navigationData.group != null) return navigationData.group!;
  
  // 3. For non-grouped routes, use route.name (or fallback to route.path)
  String basePath = route.name ?? route.path;
  
  // 4. Handle duplicates with incremental indices (-2, -3, etc.)
  // ...
}
```

### The Bug: `route.name` includes query parameters

In `DefaultRoute` constructor:
```dart
DefaultRoute(...)
  : super(
      name: canonicalUri(
        Uri(path: path, queryParameters: queryParameters).toString()
      )
    );
```

This means:
- `/page?id=1` → `route.name` = `/page?id=1`
- `/page?id=2` → `route.name` = `/page?id=2`

Since cache keys use `route.name`, these are treated as **different pages** and cause page recreation.

### Design Intent (from README.md)

The README explicitly states:

> "Navigator 2 does not support query parameters 'out of the box'... By default, Navigator 2 treats query parameters as part of the URL string and different query parameters as unique pages."
>
> "This is a problem because all of the URLs should point to the same page and query parameters should be passed to that page."

**Intent:** Query parameter changes should NOT create new pages - they should update the existing page.

---

## Supported Navigation Scenarios

### 1. **Grouped Routes** (Working Correctly)
Routes with the same `group` share a cache key.

**Use Case:** Tab navigation where different tabs (`/`, `/games`, `/apps`) should reuse the same `HomePage` widget.

```dart
NavigationData(
  label: 'games',
  url: '/games',
  group: 'home',  // All tabs share 'home' group
  builder: (context, routeData, globalData) => 
    const HomePage(tab: 'games'),
)
```

**Cache Behavior:** ✅ All routes with `group: 'home'` use cache key `'home'`

---

### 2. **Duplicate Routes** (Working Correctly)
Multiple instances of the same route path on the stack.

**Use Case:** Navigating to `/product` multiple times for different products.

**Cache Behavior:** 
- 1st instance: cache key = `/product`
- 2nd instance: cache key = `/product-2`
- 3rd instance: cache key = `/product-3`

**Why this works:** Each instance gets a unique cache key, so Flutter's Navigator treats them as separate pages. ✅

---

### 3. **Query Parameter Changes** (BROKEN - The Bug)
Navigating to the same path with different query parameters.

**Use Case:** 
- Deeplink: `/product?id=123` → `/product?id=456`
- Search filters: `/search?q=apple` → `/search?q=banana`

**Current Behavior (Broken):** 🐛
- `/product?id=123` → cache key = `/product?id=123`
- `/product?id=456` → cache key = `/product?id=456`
- Result: **Page is recreated** (initState called, old page disposed)

**Expected Behavior:**
- Both should use cache key = `/product`
- Result: **Page is updated** (didUpdateWidget called, no disposal)

---

## Why This Matters

### Problem Impact

1. **State Loss:** When a page is recreated, all state is lost (scroll position, form data, etc.)
2. **Performance:** Unnecessary widget rebuilds and disposal
3. **Lifecycle Issues:** initState/dispose called when they shouldn't be
4. **User Experience:** Jarring transitions, lost context

### Real-World Scenarios

1. **Deeplinks:** User clicks link to `/article?id=1`, then `/article?id=2` - article page shouldn't recreate
2. **Search/Filters:** Changing search query or filters should update results, not rebuild entire page
3. **Pagination:** Loading next page with `?page=2` should maintain scroll position
4. **Analytics:** Tracking page views becomes ambiguous

---

## Cache Key Requirements

Based on the codebase analysis, cache keys must support:

### ✅ Must Support (Currently Working)

1. **Grouped routes share cache key**
   - Multiple paths with same `group` → same cache key
   - Example: `/`, `/games`, `/apps` with `group: 'home'` → cache key = `'home'`

2. **Duplicate routes get unique cache keys**
   - Same path multiple times in stack → indexed keys
   - Example: `/product`, `/product`, `/product` → keys: `/product`, `/product-2`, `/product-3`

3. **Different paths get different cache keys**
   - `/home` vs `/settings` → different cache keys

### 🐛 Must Fix

4. **Same path with different query params → SAME cache key**
   - `/page?id=1` and `/page?id=2` → both use cache key `/page`
   - This allows widget updates instead of recreation

### 📋 Cache Key Decision Matrix

| Scenario | Path | Query Params | Group | Expected Cache Key |
|----------|------|--------------|-------|-------------------|
| Basic route | `/home` | none | none | `/home` |
| With query params | `/page` | `{id: '1'}` | none | `/page` (not `/page?id=1`) |
| Different query params | `/page` | `{id: '2'}` | none | `/page` (same as above!) |
| Grouped route | `/tab1` | any | `'tabs'` | `tabs` |
| Duplicate route (1st) | `/item` | none | none | `/item` |
| Duplicate route (2nd) | `/item` | none | none | `/item-2` |
| Duplicate with query | `/item` | `{id: '1'}` | none | `/item` |
| Duplicate with query (2nd) | `/item` | `{id: '2'}` | none | `/item-2` |

---

## Proposed Fix

Change line 356 in `navigation_builder.dart`:

**Current:**
```dart
String basePath = route.name ?? route.path;
```

**Fixed:**
```dart
String basePath = route.path;  // Don't use route.name which includes query params
```

This ensures:
- Query parameter changes don't affect cache keys
- Duplicate detection still works (based on path)
- Grouped routes continue to work (group takes precedence)

---

## Testing Strategy

### Test Files to Create/Update

1. **`test_cache_query_parameters.dart`** (NEW)
   - Test cache key generation with query parameters
   - Verify same path + different query params → same cache key
   - Verify widget lifecycle (update not recreate)

2. **`test_cache_key.dart`** (UPDATE)
   - Ensure existing tests still pass
   - Add query parameter test cases

3. **`test_navigation_equality_widgets.dart`** (EXISTING - Already failing)
   - Widget lifecycle tests that demonstrate the bug
   - Will pass once fix is applied

### Test Coverage Needed

- ✅ Grouped routes (already tested)
- ✅ Duplicate routes (already tested)
- 🆕 Query parameter changes (need comprehensive tests)
- 🆕 Mixed scenarios (duplicates + query params)
- 🆕 Pop and re-navigate with query params

---

## Next Steps

1. **Review this analysis** - Confirm understanding is correct
2. **Create comprehensive test file** - Test all query parameter scenarios
3. **Apply the fix** - Change `route.name` to `route.path` in cache key generation
4. **Verify all tests pass** - Both new and existing tests
5. **Update documentation** - Document the query parameter behavior

