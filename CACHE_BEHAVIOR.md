# Cache Behavior in NavigationUtils

## Overview

NavigationUtils implements intelligent page caching to optimize performance and provide a smooth navigation experience. This document explains how the caching system works and the different scenarios it supports.

> **🎯 Unique Feature:** This caching system is exclusive to NavigationUtils. Flutter's Navigator 2 and popular libraries like go_router do not include this behavior out of the box, which causes significant performance issues when there are 5+ pages in the navigation stack as all pages get rebuilt on every navigation event. NavigationUtils solves this by intelligently caching and reusing page instances, resulting in smooth, performant navigation even with deep navigation stacks.

---

## How Cache Keys Work

Cache keys are unique identifiers used to determine whether to reuse an existing page instance or create a new one. The cache key generation follows a specific priority order:

### Cache Key Priority

```
1. Explicit cacheKey (if set on the route)
   ↓
2. Group name (if route belongs to a group)
   ↓
3. Route path (without query parameters)
   ↓
4. Indexed key for duplicates (e.g., /item-2, /item-3)
```

### Visual Flow

```
generateCacheKey(navigationData, route)
    │
    ├─ Has explicit cacheKey? → Use it
    │
    ├─ Has group? → Use group name
    │
    ├─ Otherwise → Use route.path
    │
    └─ Duplicate path? → Add index (-2, -3, etc.)
```

---

## Supported Navigation Scenarios

### 1. **Grouped Routes** - Shared Widget Instances

Routes with the same `group` share a cache key, allowing multiple URLs to reuse the same widget instance.

**Use Case:** Tab navigation where different tabs should reuse the same page widget.

```dart
NavigationData(
  label: 'home',
  url: '/',
  builder: (context, routeData, globalData) => HomePage(tab: 'home'),
  group: 'home_page',
),
NavigationData(
  label: 'games',
  url: '/games',
  builder: (context, routeData, globalData) => HomePage(tab: 'games'),
  group: 'home_page',
),
NavigationData(
  label: 'apps',
  url: '/apps',
  builder: (context, routeData, globalData) => HomePage(tab: 'apps'),
  group: 'home_page',
),
```

**Result:** All three routes use cache key `'home_page'` and share the same `HomePage` widget instance. Navigating between tabs updates the widget instead of recreating it.

**Lifecycle:** `didUpdateWidget()` is called when switching tabs, preserving state.

---

### 2. **Query Parameters** - Page Updates

Routes with the same path but different query parameters share the same cache key, enabling page updates instead of recreation.

**Use Case:** Deeplinks, search, pagination, filters - scenarios where the page structure stays the same but content changes.

```dart
// Route definition
NavigationData(
  label: 'product',
  url: '/product',
  builder: (context, routeData, globalData) => ProductPage(
    id: routeData.queryParameters['id'] ?? '',
  ),
)

// Navigation examples
push('/product?id=123');  // Cache key: /product
push('/product?id=456');  // Cache key: /product (same!)
```

**Visual Explanation:**

```
User Navigation Flow:
┌─────────────────┐     ┌─────────────────┐
│  /product?id=1  │ ──▶ │  /product?id=2  │
└─────────────────┘     └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│  Cache Key:     │     │  Cache Key:     │
│   /product      │ ◀─▶ │   /product      │
│   (SAME KEY)    │     │   (SAME KEY)    │
└─────────────────┘     └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────┐
│  ✅ Same page instance maintained       │
│  ✅ didUpdateWidget() called            │
│  ✅ State preserved                     │
│  ✅ Smooth transition                   │
└─────────────────────────────────────────┘
```

**Result:** Both URLs use cache key `/product`. The page is updated with new data instead of being recreated.

**Lifecycle:** `didUpdateWidget()` is called with new query parameters, preserving state like scroll position and form data.

**Real-World Examples:**

```dart
// Deeplinks
push('/article?id=1');  → push('/article?id=2');
// Same article page, different content

// Search
push('/search?q=flutter');  → push('/search?q=dart');
// Same search page, different query

// Pagination
push('/list?page=1');  → push('/list?page=2');
// Same list page, next page of results

// Filters
push('/products');  → push('/products?category=electronics');
// Same products page, filtered results
```

---

### 3. **Duplicate Routes** - Multiple Instances

Multiple instances of the same path on the navigation stack get unique indexed cache keys.

**Use Case:** Navigating to the same route multiple times, such as viewing different products in sequence.

```dart
NavigationData(
  label: 'product',
  url: '/product',
  builder: (context, routeData, globalData) => ProductPage(
    id: routeData.queryParameters['id'] ?? '',
  ),
)

// Navigation
push('/product?id=1');  // Cache key: /product
push('/product?id=2');  // Cache key: /product-2
push('/product?id=3');  // Cache key: /product-3
```

**Result:** Each instance gets a unique cache key with an index, creating separate page instances on the stack.

**Lifecycle:** Each page has its own `initState()` and independent state.

---

### 4. **Path Parameters** - Unique Routes

Routes with path parameters are treated as distinct URLs and get separate cache keys.

```dart
NavigationData(
  label: 'product',
  url: '/product/:id',
  builder: (context, routeData, globalData) => ProductPage(
    id: routeData.pathParameters['id'] ?? '',
  ),
)

// Navigation
push('/product/123');  // Cache key: /product/123
push('/product/456');  // Cache key: /product/456
```

**Result:** Different path parameter values create different cache keys and separate page instances.

---

## Cache Key Decision Matrix

| Scenario | Example | Cache Key | Behavior |
|----------|---------|-----------|----------|
| **Grouped Routes** | `/, /games, /apps` with `group: 'home'` | `home` | Shared instance |
| **Query Parameters** | `/product?id=1`, `/product?id=2` | `/product` | Update instance |
| **Duplicate Routes** | `/item`, `/item`, `/item` | `/item`, `/item-2`, `/item-3` | Separate instances |
| **Path Parameters** | `/product/1`, `/product/2` | `/product/1`, `/product/2` | Separate instances |
| **Different Paths** | `/home`, `/settings` | `/home`, `/settings` | Separate instances |

---

## Widget Lifecycle Comparison

### Query Parameter Changes (Same Page)

```
Navigation: /page?id=1 → /page?id=2

Timeline:
  ────────────────────────────────────────────▶
  
  [Page Widget A]
  │
  │  initState()              ← Initial creation
  │  build()
  │
  │  ... User navigates to ?id=2 ...
  │
  │  didUpdateWidget()         ← Page updated!
  │  build()                   ← New data rendered
  │
  │  ... User pops back ...
  │
  │  dispose()                 ← Cleanup

  State: PRESERVED ✅
  Performance: OPTIMIZED ✅
```

### Different Routes (New Pages)

```
Navigation: /pageA → /pageB

Timeline:
  ────────────────────────────────────────────▶
  
  [Page A]              [Page B]
  │                     │
  │  initState()        │
  │  build()            │
  │                     │  initState()
  │                     │  build()
  │                     │
  │  ... User pops ...  │
  │                     │  dispose()
  │  build()            │
  │  (restored)         │
  │
  
  State: SEPARATE ✅
  Performance: STANDARD ✅
```

---

## Best Practices

### Use Groups for Tab Navigation

```dart
final routes = [
  NavigationData(
    label: 'home',
    url: '/',
    builder: (context, routeData, globalData) => HomePage(tab: 'home'),
    group: 'home_tabs',
  ),
  NavigationData(
    label: 'profile',
    url: '/profile',
    builder: (context, routeData, globalData) => HomePage(tab: 'profile'),
    group: 'home_tabs',
  ),
];
```

### Use Query Parameters for Dynamic Content

```dart
NavigationData(
  label: 'search',
  url: '/search',
  builder: (context, routeData, globalData) => SearchPage(
    query: routeData.queryParameters['q'] ?? '',
    filters: routeData.queryParameters['filters'],
  ),
)
```

### Let Duplicates Handle Multiple Instances

```dart
// No special configuration needed
NavigationData(
  label: 'item',
  url: '/item',
  builder: (context, routeData, globalData) => ItemPage(
    id: routeData.queryParameters['id'] ?? '',
  ),
)

// Automatically handles:
push('/item?id=1');  // First instance
push('/item?id=2');  // Second instance (indexed)
push('/item?id=3');  // Third instance (indexed)
```

### Use Explicit Cache Keys for Custom Behavior

```dart
final route = DefaultRoute(
  path: '/custom',
  cacheKey: 'my_custom_key',  // Explicit control
);
```

---

## Cache Management

### Clearing Cache

```dart
// Clear all cached pages
NavigationBuilder.clearCache();

// Typically done between tests or when resetting navigation state
```

### Cache Lifecycle

The cache is automatically managed by NavigationBuilder:

1. **Page Creation:** New pages are added to cache with their cache key
2. **Page Reuse:** Existing pages are retrieved from cache when navigated to
3. **Page Removal:** Pages are removed from cache when popped from stack
4. **Cache Cleanup:** Unused entries are automatically cleaned up

---

## Summary

NavigationUtils provides intelligent caching that:

- ✅ **Preserves state** across query parameter changes
- ✅ **Optimizes performance** by reusing widget instances when appropriate
- ✅ **Supports multiple navigation patterns** (groups, duplicates, parameters)
- ✅ **Maintains smooth transitions** with proper lifecycle management
- ✅ **Gives you control** with explicit cache keys when needed
- ✅ **Solves the deep stack problem** that affects Flutter Navigator 2 and go_router

The caching system works automatically based on your route configuration, requiring no additional code for common scenarios.

### Performance Advantage

Unlike Flutter's default Navigator 2 implementation and popular routing libraries like go_router, NavigationUtils caches page instances to prevent unnecessary rebuilds. Without this caching:

- **5+ pages in the stack** → All pages rebuild on every navigation
- **10+ pages** → Noticeable lag and jank
- **Complex pages** → Performance degrades exponentially

With NavigationUtils' intelligent caching:

- **Pages are reused** → Only affected pages rebuild
- **State is preserved** → Smooth, instant transitions
- **Scalable performance** → No degradation with deep stacks

This is a **unique feature** that sets NavigationUtils apart from other Flutter navigation solutions.
