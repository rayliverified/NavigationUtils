# Flutter Navigator 2 Page Update Mechanism

## Executive Summary

This document explains a critical but undocumented behavior in Flutter's Navigator 2.0 regarding how Pages and Routes handle updates. Understanding this mechanism is essential for implementing features like **grouped routes** where multiple URLs share a single widget instance.

**Key Discovery**: When implementing custom Page classes for Navigator 2, the Route **MUST** read the child widget at **build time**, not at Route creation time. Using `PageRouteBuilder` captures the child in a closure and prevents updates from ever being reflected in the UI.

## The Problem: Grouped Routes

Grouped routes allow multiple URLs to share a single widget instance. For example, an authentication flow might have:

- `/login` - Login page
- `/signup` - Signup page
- `/reset-password` - Password reset page

All three share an `AuthPage` widget that displays different content based on the current route. The goal is:

1. **Widget Reuse**: The same `AuthPage` instance is kept alive
2. **State Preservation**: Form data, scroll positions, animations persist
3. **Efficient Updates**: `didUpdateWidget` is called instead of `initState`

## How Flutter Navigator 2 Updates Pages

### The Page Matching Process

When Navigator's pages list changes, Flutter compares old pages with new pages using `Page.canUpdate`:

```dart
// Flutter's default implementation
bool canUpdate(Page other) {
  return other.runtimeType == runtimeType && other.key == key;
}
```

If `canUpdate` returns `true`:
1. The existing Route is **reused**
2. `Route._updateConfig(newPage)` is called to update `settings`
3. The Route should rebuild with the new Page's child

If `canUpdate` returns `false`:
1. A **new Route** is created
2. Old Route is disposed
3. `initState` is called on the new widget (not `didUpdateWidget`)

### The Critical Insight: When Does the Child Update?

This is where the undocumented behavior matters. After `canUpdate` returns `true`:

1. `settings` now points to the **new Page**
2. The Route needs to rebuild to show the new child
3. **HOW** the Route accesses the child determines if it updates

## The Closure Capture Problem

### PageRouteBuilder: The Wrong Way

```dart
class BrokenNoTransitionPage extends Page<void> {
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,  // CAPTURED!
      transitionDuration: Duration.zero,
    );
  }
}
```

**Why this fails:**

1. `createRoute` is called **once** when the Route is first created
2. The `child` variable is captured in the `pageBuilder` closure
3. Even when `_updateConfig(newPage)` is called, the closure still holds the **old** child
4. The UI **never updates** to show the new page

### The Fix: Read Child at Build Time

```dart
class CorrectNoTransitionPage extends Page<void> {
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return _CorrectNoTransitionRoute(page: this);
  }
}

class _CorrectNoTransitionRoute extends PageRoute<void> {
  _CorrectNoTransitionRoute({required CorrectNoTransitionPage page})
      : super(settings: page);

  CorrectNoTransitionPage get _page => settings as CorrectNoTransitionPage;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _page.child;  // Read from CURRENT settings at BUILD TIME
  }
}
```

**Why this works:**

1. `_page` reads from `settings`, which is updated by `_updateConfig(newPage)`
2. When the Route rebuilds, `buildPage` reads `_page.child`
3. `_page` now points to the **new Page** with the **new child**
4. Flutter sees a different child widget and calls `didUpdateWidget`

## Visual Comparison

```
BROKEN (PageRouteBuilder):
┌─────────────────────────────────────────────────────────────────┐
│ Page Update Flow                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Navigate /login → /signup                                    │
│                                                                  │
│  2. canUpdate returns true (same key 'auth')                     │
│                                                                  │
│  3. Route._updateConfig(newPage with SignupWidget)               │
│       └── settings = newPage                                     │
│                                                                  │
│  4. Route rebuilds                                               │
│       └── pageBuilder closure returns captured LoginWidget       │
│           (closure STILL has old child!)                         │
│                                                                  │
│  5. UI shows LoginWidget  ❌ WRONG!                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

CORRECT (Custom Route):
┌─────────────────────────────────────────────────────────────────┐
│ Page Update Flow                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Navigate /login → /signup                                    │
│                                                                  │
│  2. canUpdate returns true (same key 'auth')                     │
│                                                                  │
│  3. Route._updateConfig(newPage with SignupWidget)               │
│       └── settings = newPage                                     │
│                                                                  │
│  4. Route rebuilds                                               │
│       └── buildPage reads _page.child                            │
│           └── _page = settings = newPage                         │
│           └── returns SignupWidget                               │
│                                                                  │
│  5. UI shows SignupWidget  ✓ CORRECT!                            │
│     └── didUpdateWidget called (same widget type, different props)│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Implementation Guidelines

### DO: Create Custom Route Classes

```dart
class MyCustomPage extends Page<void> {
  final Widget child;

  const MyCustomPage({required this.child, super.key, super.name});

  @override
  Route<void> createRoute(BuildContext context) {
    return _MyCustomRoute(page: this);
  }
}

class _MyCustomRoute extends PageRoute<void> {
  _MyCustomRoute({required MyCustomPage page}) : super(settings: page);

  MyCustomPage get _page => settings as MyCustomPage;

  // Read from _page at build time
  @override
  Widget buildPage(...) => _page.child;

  // Other overrides...
}
```

### DON'T: Use PageRouteBuilder

```dart
// NEVER do this for Pages that need to update!
@override
Route<void> createRoute(BuildContext context) {
  return PageRouteBuilder(
    settings: this,
    pageBuilder: (_, __, ___) => child,  // child is captured forever
  );
}
```

### DO: Keep Arguments Consistent for Route Reuse

For Routes to be reused (enabling `didUpdateWidget()`), the Page's `arguments` must match. NavigationUtils achieves this by:

1. **Not passing query parameters as arguments** - Query params are available via `routeData.queryParameters`, not `Page.arguments`
2. **Using the same `route.arguments` for all routes** - This ensures `canUpdate` returns `true`

```dart
// canUpdate checks arguments for equality
@override
bool canUpdate(Page other) {
  return other.runtimeType == runtimeType &&
      other.key == key &&
      other.arguments == arguments;
}

// When building pages, don't pass query params as arguments
page = buildPage(
  key: pageKey,
  arguments: route.arguments,  // NOT route.queryParameters
  child: navigationData.builder(...),
);
```

This ensures Routes are reused when the key and arguments are the same, enabling `didUpdateWidget()` for:
- **Grouped routes**: Same group name = same key, same arguments = Route reused
- **Query parameter changes**: Same path = same key, same arguments = Route reused

## How MaterialPageRoute Gets It Right

Flutter's built-in `MaterialPageRoute` uses this pattern correctly:

```dart
// From Flutter's MaterialPageRoute
class _PageBasedMaterialPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _PageBasedMaterialPageRoute({required MaterialPage<T> page})
      : super(settings: page);

  MaterialPage<T> get _page => settings as MaterialPage<T>;

  @override
  Widget buildContent(BuildContext context) {
    return _page.child;  // Read at build time!
  }
}
```

## Common Pitfalls

### Pitfall 1: Using const Constructors on Child Widgets

**This is critical for grouped routes.** Flutter uses object identity to detect widget changes. When you use `const`, Flutter returns the exact same widget instance every time, preventing change detection.

```dart
// ❌ WRONG: const prevents Flutter from detecting changes!
NavigationData(
  label: 'login',
  url: '/login',
  group: 'auth',
  builder: (context, route, _) => const AuthPage(),  // Same instance every time!
),
NavigationData(
  label: 'signup',
  url: '/signup',
  group: 'auth',
  builder: (context, route, _) => const AuthPage(),  // Same instance every time!
),
```

**What happens:**
1. User navigates from `/login` to `/signup`
2. Route is reused (same group key, `canUpdate` returns true)
3. `buildPage` is called, which calls the builder
4. Builder returns `const AuthPage()` - the **exact same object** as before
5. Flutter's element tree compares old child with new child
6. They're identical (same object) → **no `didUpdateWidget()` called**
7. UI doesn't change!

**The fix:** Always pass at least one property that differs between grouped routes:

```dart
// ✅ CORRECT: Different properties = different widget = didUpdateWidget called
NavigationData(
  label: 'login',
  url: '/login',
  group: 'auth',
  builder: (context, route, _) => AuthPage(pageType: 'login'),
),
NavigationData(
  label: 'signup',
  url: '/signup',
  group: 'auth',
  builder: (context, route, _) => AuthPage(pageType: 'signup'),
),

// Or use route data:
builder: (context, route, _) => AuthPage(pageType: route.path),
```

**Why it works:** `AuthPage(pageType: 'login')` and `AuthPage(pageType: 'signup')` are different widget instances with different properties. Flutter detects the property change and calls `didUpdateWidget()`.

### Pitfall 2: Caching the Page in _pageCache

If your navigation library caches Pages, make sure to create NEW Page instances when the child changes, not reuse cached ones.

### Pitfall 3: Not Triggering Route Rebuild

After `_updateConfig` is called, the Route needs to rebuild. Most PageRoute subclasses handle this automatically, but if you're using a custom Route, ensure `build` or `buildPage` is called again.

## Testing Grouped Routes

```dart
testWidgets('Grouped routes call didUpdateWidget', (tester) async {
  int initCount = 0;
  int updateCount = 0;

  final delegate = DefaultRouterDelegate(
    navigationDataRoutes: [
      NavigationData(
        url: '/login',
        group: 'auth',
        builder: (_, __, ___) => TestWidget(
          onInit: () => initCount++,
          onUpdate: () => updateCount++,
        ),
      ),
      NavigationData(
        url: '/signup',
        group: 'auth',
        builder: (_, __, ___) => TestWidget(
          onInit: () => initCount++,
          onUpdate: () => updateCount++,
        ),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(...));

  delegate.push('login');
  await tester.pumpAndSettle();
  expect(initCount, 1);

  delegate.push('signup');
  await tester.pumpAndSettle();

  expect(initCount, 1);  // Same instance reused
  expect(updateCount, greaterThan(0));  // didUpdateWidget called
});
```

## Summary

| Aspect | PageRouteBuilder | Custom Route |
|--------|------------------|--------------|
| Child access | Closure capture (creation time) | `_page.child` (build time) |
| Page updates | ❌ Never reflected | ✓ Properly reflected |
| Grouped routes | ❌ Broken | ✓ Works correctly |
| didUpdateWidget | ❌ Never called | ✓ Called on updates |

**The golden rule**: Always read the child from `settings` (the Page) at build time, never capture it in a closure.

## References

- Flutter Navigator 2.0 source: [navigator.dart](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/widgets/navigator.dart)
- MaterialPageRoute implementation: [page.dart](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/material/page.dart)
- NavigationUtils library tests: `test/custom_page_builder_test.dart`
