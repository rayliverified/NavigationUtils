# 📚 Duplicate Routes - Cache Key System Documentation

**How NavigationUtils Handles Multiple Instances of the Same Route**  
**Date:** October 28, 2025

---

## 🎯 Overview

NavigationUtils supports **multiple instances** of the same route path in the navigation stack. This is essential for real-world navigation patterns where users can navigate to the same type of page multiple times (e.g., opening multiple product details, articles, or search results).

### The Challenge

Flutter's Navigator requires **unique keys** for each page in the stack. If you try to use the same key twice, Navigator cannot distinguish between the pages, causing:
- ❌ Pages not rendering correctly
- ❌ Animation issues
- ❌ Pop behavior problems

### The Solution: Indexed Cache Keys

NavigationUtils implements an **automatic indexing system** that:
- ✅ Assigns unique cache keys to duplicate routes
- ✅ Uses incremental suffixes (`-2`, `-3`, etc.)
- ✅ Reuses indices when routes are removed
- ✅ Maintains proper Navigator behavior

---

## 🔑 Cache Key Generation System

### Base Algorithm

```dart
generateCacheKey(navigationData, route) {
  // 1. Use explicit cache key if provided
  if (route.cacheKey != null) return route.cacheKey;
  
  // 2. Use group name for grouped routes
  if (navigationData.group != null) return navigationData.group;
  
  // 3. For regular routes, use path as base key
  String basePath = route.path;
  
  // 4. Check if this path already exists in the stack
  if (!_pageCache.containsKey(basePath)) {
    return basePath;  // First instance gets base key
  }
  
  // 5. Find next available index for duplicates
  int index = 2;
  while (_pageCache.containsKey('$basePath-$index')) {
    index++;
  }
  return '$basePath-$index';  // e.g., /product-2, /product-3
}
```

### Key Components

1. **`_pageCache`** - Map of cache keys to Page objects
   - Tracks which pages are currently in the stack
   - Used to check for existing keys

2. **`_routeIndices`** - Map of base paths to highest index used
   - Tracks the highest index assigned for each path
   - Helps with efficient index assignment

---

## 📊 Cache Key Examples

### Example 1: Simple Duplicates

```
Navigation Flow:
/product  →  /product  →  /product

Cache Keys Generated:
/product  →  /product-2  →  /product-3

Navigator Stack:
┌─────────────────────┐
│ Key: /product-3     │ ← Top
├─────────────────────┤
│ Key: /product-2     │
├─────────────────────┤
│ Key: /product       │ ← Bottom
└─────────────────────┘
```

### Example 2: With Query Parameters

**After the fix** (query params don't affect cache key):

```
Navigation Flow:
/product?id=1  →  /product?id=2  →  /product?id=3

Cache Keys Generated:
/product  →  /product-2  →  /product-3

Note: All have different query params but same base path
```

### Example 3: Pop and Re-Push

```
Navigation Flow:
1. Push /item  →  Cache key: /item
2. Push /item  →  Cache key: /item-2
3. Pop         →  /item-2 removed from cache
4. Push /item  →  Cache key: /item-2 (reuses index)

The system finds the lowest available index!
```

### Example 4: Mixed Routes

```
Navigation Flow:
/home  →  /product  →  /settings  →  /product

Cache Keys:
/home  →  /product  →  /settings  →  /product-2

Stack:
┌─────────────────────┐
│ /product-2          │ ← Different product instance
├─────────────────────┤
│ /settings           │
├─────────────────────┤
│ /product            │ ← First product instance
├─────────────────────┤
│ /home               │
└─────────────────────┘
```

---

## 🔄 Index Reuse System

### How Indices Are Reused

When a route is removed (popped), its index can be reused:

```dart
clearCachedRoute(route) {
  _pageCache.remove(route.cacheKey);
  
  // If removing an indexed route (e.g., /item-2)
  if (route.cacheKey.contains('-')) {
    // Update _routeIndices to track next available index
    // This allows the index to be reused
  }
}
```

### Example: Index Gaps

```
Initial State:
Stack: [/item, /item-2, /item-3]
_routeIndices['/item'] = 3

Pop /item-2:
Stack: [/item, /item-3]
_routeIndices['/item'] = 3  (unchanged)

Push /item again:
Algorithm checks: /item? (exists) → /item-2? (doesn't exist) → Use /item-2!
Stack: [/item, /item-3, /item-2]

Result: Index 2 is reused, no gaps in efficiency
```

---

## 🎓 Use Cases & Scenarios

### Use Case 1: Product Detail Pages

```dart
// User flow: Browse → Product A → Browse → Product B → Product A again

Navigator Stack:
1. /products (browse)
2. /product?id=123 (Product A) - cache key: /product
3. /products (back to browse) - REPLACED (grouped route)
4. /product?id=456 (Product B) - cache key: /product-2
5. /product?id=123 (Product A again) - cache key: /product-3

✅ Three separate product instances can coexist
✅ Each maintains its own state
✅ User can navigate back through all of them
```

### Use Case 2: Article Reader

```dart
// User flow: Article 1 → Related Article 2 → Related Article 3

Navigator Stack:
1. /article?id=1 - cache key: /article
2. /article?id=2 - cache key: /article-2
3. /article?id=3 - cache key: /article-3

✅ User can read related articles
✅ Back button goes through article history
✅ Each article maintains scroll position
```

### Use Case 3: Search → Results → Search Again

```dart
// User flow: Search "flutter" → Results → Search "dart" → Results

Navigator Stack:
1. /search?q=flutter - cache key: /search
2. /results?q=flutter - cache key: /results
3. /search?q=dart - cache key: /search-2
4. /results?q=dart - cache key: /results-2

✅ Can navigate back to previous searches
✅ Each search/results pair is independent
```

### Use Case 4: Tab Navigation with Details

```dart
// User flow: Home Tab → Item A → Explore Tab → Item B → Profile Tab

Navigator Stack with Groups:
1. / (home tab) - cache key: tabs (group)
2. /item?id=1 (Item A) - cache key: /item
3. /explore (tab) - cache key: tabs (group, replaces home)
4. /item?id=2 (Item B) - cache key: /item-2
5. /profile (tab) - cache key: tabs (group, replaces explore)

✅ Tabs don't stack (same group)
✅ Items do stack (different instances)
```

---

## ⚙️ Special Behaviors

### Grouped Routes

Grouped routes **DO NOT** use the indexing system:

```dart
// All use the SAME cache key: 'home_group'
NavigationData(url: '/', group: 'home_group')
NavigationData(url: '/feed', group: 'home_group')
NavigationData(url: '/profile', group: 'home_group')

// Pushing any of these replaces the previous one
// They cannot coexist in the stack
```

**Why?** Groups represent the same logical page (like tabs), so they should replace each other.

### Explicit Cache Keys

If you provide an explicit `cacheKey`, the system respects it:

```dart
DefaultRoute(
  path: '/custom',
  cacheKey: 'my-special-key'  // System won't index this
)
```

**Warning:** Be careful! Explicit keys bypass duplicate protection. If you push two routes with the same explicit key, Navigator will break.

---

## 🧪 Testing Scenarios

### Scenario 1: Simple Duplicate Detection

```dart
test('Push same route twice creates indexed keys') {
  // Push /item first time
  final key1 = generateCacheKey(navData, route1);
  expect(key1, '/item');
  
  // Push /item second time
  final key2 = generateCacheKey(navData, route2);
  expect(key2, '/item-2');
  
  // Push /item third time
  final key3 = generateCacheKey(navData, route3);
  expect(key3, '/item-3');
}
```

### Scenario 2: Index Reuse After Pop

```dart
test('Popped routes allow index reuse') {
  // Create stack: /item, /item-2, /item-3
  // ... 
  
  // Pop /item-2
  clearCachedRoute(route2);
  
  // Push /item again
  final key4 = generateCacheKey(navData, route4);
  expect(key4, '/item-2');  // Reuses index 2
}
```

### Scenario 3: Query Params Don't Affect Indexing

```dart
test('Query params create duplicates when path is same') {
  final route1 = DefaultRoute(path: '/item', queryParams: {'id': '1'});
  final route2 = DefaultRoute(path: '/item', queryParams: {'id': '2'});
  
  final key1 = generateCacheKey(navData, route1);
  final key2 = generateCacheKey(navData, route2);
  
  expect(key1, '/item');
  expect(key2, '/item-2');  // Different instance despite different query params
}
```

### Scenario 4: Mixed Routes Don't Interfere

```dart
test('Different routes maintain separate indices') {
  // Push /item twice
  final itemKey1 = generateCacheKey(itemNav, itemRoute1);
  final itemKey2 = generateCacheKey(itemNav, itemRoute2);
  
  // Push /product twice
  final prodKey1 = generateCacheKey(prodNav, prodRoute1);
  final prodKey2 = generateCacheKey(prodNav, prodRoute2);
  
  expect(itemKey1, '/item');
  expect(itemKey2, '/item-2');
  expect(prodKey1, '/product');
  expect(prodKey2, '/product-2');  // Separate counter
}
```

---

## 🔍 Implementation Details

### Cache Management Flow

```
User pushes route → NavigationBuilder.build() called
                          ↓
            Generate cache key for route
                          ↓
            Check if cache key exists in _pageCache
                          ↓
        ┌─────────────────┴─────────────────┐
        ↓                                   ↓
    Exists                            Doesn't Exist
    Reuse Page                        Create New Page
        ↓                                   ↓
    Update in newCache              Add to newCache
        ↓                                   ↓
        └─────────────────┬─────────────────┘
                          ↓
            Replace _pageCache with newCache
                          ↓
                Pages built for Navigator
```

### Why Two Caches?

1. **`_pageCache`** (persistent)
   - Tracks pages between builds
   - Used for cache key existence checks
   - Enables page reuse

2. **`newCache`** (temporary)
   - Built during each build cycle
   - Only includes pages in current stack
   - Replaces _pageCache at end of build

**Benefit:** Removed routes are automatically cleaned up!

---

## 🎯 Key Takeaways

### ✅ What Works

1. **Multiple instances** of same route → Different cache keys
2. **Query param changes** → Same cache key (after fix), but can still duplicate
3. **Pop and re-push** → Index reuse for efficiency
4. **Mixed route types** → Independent index tracking
5. **Grouped routes** → No indexing, mutual replacement

### ⚠️ Important Notes

1. **Cache keys must be unique** - This is the whole point!
2. **Query params** - Don't affect cache key base, but duplicates still possible
3. **Groups** - Bypass the indexing system entirely
4. **Explicit keys** - Use with caution, no duplicate protection

### 🎨 Mental Model

Think of cache keys like **apartment numbers**:
- Building address = route path (`/product`)
- Apartment number = index (`` for first, `-2` for second)
- Each apartment is a separate instance
- When one is vacated, the number can be reused
- Groups = One apartment that gets renovated with different tenants (tabs)

---

## 📈 Performance Considerations

### Efficient Index Finding

```dart
// ✅ GOOD: Find first available gap
while (_pageCache.containsKey('$basePath-$index')) {
  index++;
}

// ❌ BAD: Would need to track all gaps
// Our system naturally handles gaps through cache removal
```

### Memory Management

- Pages removed from stack → Removed from cache automatically
- No memory leaks from orphaned pages
- Indices reused → No unbounded growth

### Build Performance

- Cache lookups are O(1) hash map operations
- Index finding is O(n) where n = number of duplicates
- Typically n is small (2-5), so very fast

---

## 🚀 Future Enhancements

Possible improvements to consider:

1. **Configurable index strategy**
   ```dart
   // Option to disable indexing for certain routes
   NavigationData(
     url: '/singleton',
     allowDuplicates: false  // Throw or replace instead
   )
   ```

2. **Index limit**
   ```dart
   // Prevent too many duplicates
   NavigationData(
     url: '/article',
     maxInstances: 5  // Limit stack depth for this route
   )
   ```

3. **Custom index format**
   ```dart
   // Custom suffix instead of -2, -3
   indexFormat: (path, index) => '$path_v$index'
   // Results: /item_v1, /item_v2, etc.
   ```

---

## 📚 Related Documentation

- **Query Parameter Handling**: See `CACHE_BEHAVIOR_ANALYSIS.md`
- **Group Routes**: See Navigator 2.0 documentation
- **Cache Key Fix**: See `CACHE_FIX_SUMMARY.md`

---

**Questions or Issues?**

If duplicate route handling isn't working as expected:
1. Check cache keys with debug logging
2. Verify routes aren't grouped (groups replace, don't duplicate)
3. Ensure cache isn't being cleared unexpectedly
4. Review test cases in `test/test_duplicate_routes_comprehensive.dart`

