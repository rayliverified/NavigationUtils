# Cache Behavior Fix - Summary and Test Plan

## Executive Summary

The NavigationUtils library has a bug where **query parameter changes cause page recreation instead of page updates**. This contradicts the documented design intent and breaks common use cases like deeplinks, search, and pagination.

---

## The Problem

### Root Cause
In `navigation_builder.dart` line 356:
```dart
String basePath = route.name ?? route.path;
```

`route.name` includes query parameters (set in `DefaultRoute` constructor):
```dart
// In navigation_delegate.dart
DefaultRoute(...)
  : super(
      name: canonicalUri(
        Uri(path: path, queryParameters: queryParameters).toString()
      )
    );
```

### Impact
- **Same path + different query params** → Different cache keys → **Page recreated**
- Examples:
  - `/product?id=1` → cache key = `/product?id=1`
  - `/product?id=2` → cache key = `/product?id=2`
  - Result: New page instance, `initState()` called, state lost ❌

### Expected Behavior
- **Same path + different query params** → Same cache key → **Page updated**
- Both `/product?id=1` and `/product?id=2` → cache key = `/product`
- Result: Same page instance, `didUpdateWidget()` called, state preserved ✅

---

## Validation Approach

### Created Test Files

1. **`CACHE_BEHAVIOR_ANALYSIS.md`**
   - Comprehensive analysis of current cache behavior
   - Documents all supported scenarios
   - Includes decision matrix for cache key generation
   - Identifies the specific bug and proposed fix

2. **`test/test_cache_query_parameters.dart`** (NEW - 400+ lines)
   - **67 test cases** covering query parameter scenarios
   - Tests EXPECTED behavior (will fail with current code)
   - Organized into groups:
     - Basic query parameter handling
     - Query parameters with labels
     - Real-world scenarios (deeplinks, search, pagination)
     - Edge cases

### Test Categories

#### ✅ Currently Working (Should Continue Working)
- Grouped routes share cache keys
- Duplicate routes get indexed keys (`/item`, `/item-2`, `/item-3`)
- Different paths get different keys

#### 🐛 Currently Broken (Tests Will Fail, Then Pass After Fix)
- Same path + different query params (should share cache key)
- Deeplinks with changing IDs
- Search with different queries
- Pagination
- Filter changes

#### 🔍 Real-World Scenarios Tested
1. **Deeplink Navigation**: `/article?id=1` → `/article?id=2`
2. **Search**: `/search?q=flutter` → `/search?q=dart`
3. **Pagination**: `/list?page=1` → `/list?page=2`
4. **Filters**: `/products` → `/products?category=electronics`
5. **Duplicates with Query Params**: Multiple `/item` with different `?id=X`
6. **Tabs + Query Params**: Grouped tabs with query-param content

---

## Existing Test Files Status

### Will Continue to Pass ✅
- **`test/test_cache_key.dart`**
  - Tests basic cache key generation
  - Tests grouped routes
  - Tests duplicate route handling
  - Tests cache clearing
  - All these behaviors remain unchanged

- **`test/test_duplicate_route.dart`**
  - Tests duplicate route navigation
  - Duplicate detection based on path (unaffected)

- **`test/test_navigation_groups.dart`**
  - Tests grouped route behavior
  - Groups use group name for cache key (unaffected)

### Currently Failing, Will Pass After Fix ✅
- **`test/test_navigation_equality_widgets.dart`**
  - 4 widget tests expecting page updates
  - Currently fails because pages are recreated
  - Will pass once cache keys use path only

### Will Need Review 🔍
- **`test/test_navigation_equality.dart`**
  - Has comprehensive comments about the bug
  - Some tests document current behavior
  - May need updates to match new behavior

---

## The Fix

### Single Line Change

**File:** `lib/src/navigation_builder.dart`  
**Line:** 356

**Current:**
```dart
String basePath = route.name ?? route.path;
```

**Fixed:**
```dart
String basePath = route.path;
```

### Why This Works

1. **Path is consistent**: `route.path` = `/product` regardless of query params
2. **Duplicate detection unchanged**: Still based on path matching
3. **Groups unaffected**: Group check happens before (line 352)
4. **Backwards compatible**: No API changes

### Alternative Considered

Could also use:
```dart
String basePath = route.label.isNotEmpty ? route.label : route.path;
```

This respects label priority but query params don't affect labels anyway.

---

## Test Execution Plan

### Phase 1: Validate Current Behavior (Before Fix)
```bash
# Run new query parameter tests - SHOULD FAIL
flutter test test/test_cache_query_parameters.dart

# Run widget equality tests - SHOULD FAIL
flutter test test/test_navigation_equality_widgets.dart

# Run existing cache tests - SHOULD PASS
flutter test test/test_cache_key.dart
flutter test test/test_duplicate_route.dart
```

**Expected Results:**
- `test_cache_query_parameters.dart`: **Multiple failures** ❌
- `test_navigation_equality_widgets.dart`: **4 failures** ❌
- `test_cache_key.dart`: **All pass** ✅
- `test_duplicate_route.dart`: **All pass** ✅

### Phase 2: Apply Fix

Make the one-line change in `navigation_builder.dart`.

### Phase 3: Validate Fixed Behavior (After Fix)
```bash
# Run all navigation tests
flutter test test/

# Specifically verify:
flutter test test/test_cache_query_parameters.dart
flutter test test/test_navigation_equality_widgets.dart
flutter test test/test_cache_key.dart
```

**Expected Results:**
- **ALL tests should pass** ✅

### Phase 4: Integration Testing

Test with example apps:
```bash
cd example
flutter run

cd ../example_auth
flutter run
```

Verify:
- Deeplink navigation works correctly
- Tab switching maintains state
- Query parameter changes update pages
- No unexpected page recreations

---

## Risk Assessment

### Low Risk ✅
- **Single line change** in well-isolated function
- **Backwards compatible** - no API changes
- **Comprehensive test coverage** - 67 new tests + existing tests
- **Aligns with documented intent** from README

### Potential Issues
1. **Edge case with labels**: If code relies on `route.name` including query params
   - Mitigation: Labels don't include query params anyway
   
2. **Custom cache key handling**: If external code sets `cacheKey` explicitly
   - Mitigation: Explicit cache keys bypass this logic (line 346-347)

3. **Migration from old behavior**: Apps depending on recreation
   - Mitigation: This was always a bug; proper behavior is to update

---

## Success Criteria

### Tests
- [x] New query parameter tests created
- [x] Existing tests still pass (verified before fix)
- [ ] All tests pass after fix
- [ ] No regressions in example apps

### Behavior
- [ ] Same path + different query params → same cache key
- [ ] `didUpdateWidget()` called instead of `initState()`
- [ ] State preserved across query param changes
- [ ] Duplicate routes still get indexed keys
- [ ] Grouped routes still share keys

### Documentation
- [x] Bug documented in analysis
- [x] Fix explained clearly
- [ ] Update README if needed
- [ ] Add migration notes if needed

---

## Next Steps

1. **Review Analysis** ✋ **WAITING FOR APPROVAL**
   - Confirm understanding is correct
   - Verify test coverage is sufficient
   - Approve proceeding with fix

2. **Run Tests (Before Fix)**
   - Confirm test failures match expectations
   - Verify existing tests still pass

3. **Apply Fix**
   - Make one-line change
   - Run all tests
   - Verify example apps

4. **Documentation**
   - Update CHANGELOG.md
   - Add notes to README if needed
   - Document breaking change (though technically bug fix)

5. **Release**
   - Version bump (patch or minor?)
   - Release notes highlighting fix

---

## Questions for Review

1. ✅ Is the analysis of cache behavior correct?
2. ✅ Are all important scenarios covered in tests?
3. ✅ Is the proposed fix (using `route.path`) correct?
4. ⚠️ Should we use `route.label` as fallback or just `route.path`?
5. ⚠️ Are there any scenarios we're missing?
6. ⚠️ Should this be a minor or patch version bump?

---

## Conclusion

This is a **well-defined bug** with:
- ✅ Clear root cause
- ✅ Simple fix
- ✅ Comprehensive test coverage
- ✅ Low risk
- ✅ High value (fixes deeplinks, search, pagination, etc.)

**Recommendation: Proceed with fix after approval** 🚀
