## 0.9.8
- Fix `runFunction` deeplink execution behavior.

## 0.9.7
- Fix `runFunction` query parameters not being passed and redirect call order. The `runFunction` now correctly runs after navigation.

## 0.9.6
- Fix `runFunction` not being called when `shouldNavigateDeeplinkFunction` returns false. The `runFunction` is now always called regardless of whether navigation happens or not, allowing deeplink handlers to execute logic (e.g., analytics, showing dialogs) even when navigation is blocked.

## 0.9.5
- Add `runFunction` parameter to `DeeplinkDestination` class. Support handling deeplinks without navigating, such as allowing deeplinks to trigger app functionalities (e.g., analytics, social share links, or showing a bottom sheet) without navigating to a new page. It is invoked after navigation completes, which allows for logic to be run after deeplink navigation is complete.

## 0.9.4
### Enabling Hot Reload for Routes

When developing, you may add or change routes and expect hot reload to pick up the updates. To enable hot reload:

1. Change `routes` to a getter.
    ```dart
    // Old
    List<NavigationData> routes = [];
    // New
    List<NavigationData> get routes => [];
    ```
2. Add a `reassemble` method to the top level `App` widget.
    ```dart
    @override
    void reassemble() {
      NavigationManager.instance.routerDelegate.navigationDataRoutes = routes;
      super.reassemble();
    }
    ```

## 0.9.3
- Add cache key to `setNewRoute` and `_setNewRouteHistory`.
  - Update cache key index calculation logic.

## 0.9.2
- Consolidate cache key and unique key into an unified indentifier system.
  - Fix duplicate and grouped route cache handling.
- Implement clear cache properly for all navigation methods.

## 0.9.1
- Create empty route fallback for `customDeeplinkHandler`. Initial app open always requires a route to be set and cannot be empty.
- Fix cached pages not being cleared when popped.

## 0.9.0
- **Breaking:** Rename `pageBuilder` to `migrationPageBuilder`.
- Add support for passing a custom `pageBuilder` instead of using the default MaterialPage or CupertinoPage.
- Customize PageTransitions with a custom `pageBuilder`.
  - Set a global `pageBuilder` in DefaultRouteDelegate to override the default page behavior across the entire app.
  - Override individual page transitions by setting the `pageBuilder` on individual NavigationDatas.

## 0.8.0
- Create NavigationBuilder page caching to properly reuse page instances.
  - See an up to 10x performance increase from not rebuilding the entire page stack.
  - Any changes to groups, paths, query parameters that results in a URL change will now properly rebuild.

## 0.7.9
- Create OptimizedPage variants to optimize page rebuilds.
  - Workaround an internal Navigator [issue](https://github.com/flutter/flutter/issues/135596) which causes unnecessary page rebuilds.

## 0.7.8
- Create a new Page Key system to generate unique keys for each Page.
  - Optimize rebuilds by assigning unique keys to each page.
  - Add support for duplicate page routes.
  - Add support for groups by assigning groups a consolidated group key.
- Fix duplicate route removal. Remove routes in reverse order. 
  - When there are multiple pages with the same label, the topmost one is removed first.

## 0.7.7
- Loosen Flutter constraints to prepare for Predictive Back Navigation breaking change.

## 0.7.5
- Fix `initialRoute` incorrectly parsing query parameters as path.
- Update examples to Flutter v3.24.0.

## 0.7.4
- Add `NavigationManager.instance.routes` convenience method for accessing the list of active routes.
- Add `onPopPage` callback to `DefaultRouterDelegate` for overriding global back navigation.

## 0.7.3
- Create `removeGroup` function for removing Nested Navigation groups.
- Add option to set the NavigationListenerMixin's route name.
  - Set and override the `routeName` of the current page.

## 0.7.2
- Simplify Nested Navigation `NavigationManager.nested` usage by bundling `_removeDuplicateWidgets` functionality by default.
- Add Nested Tabs example.

## 0.7.1
- New AnimatedStack widget makes it easy to build nested navigation!
  - Add custom page transition animations. Use any of Flutter's built in transitions like `FadeTransition`, `ScaleTransition`, etc.
  - Or, use the included `SharedAxisAnimation` and `FadeThroughAnimation` effects.
- Optimized performance! AnimatedStack is optimized to prevent page rebuilds.

## 0.7.0
- Nested Navigation support. Welcome to the easiest nested navigation ever!
  - Build nested routes with `NavigationManager.instance.nested()`.
  - Assign the same `group` parameter to each `NavigationData` to define a nested route.
  - Support 100% customizable page transitions.

## 0.6.0
- Flutter v3.22.0 support.
- Add URL alias `group` and Deeplink `redirectFunction` documentation.
- Fix `setMainRoutes` not set correctly.
- Simplify Auth Example authentication code.

## 0.5.2
- Fix Redirect not applying default navigation.

## 0.5.1
- Fix DefaultRoute incorrect group equality comparator on null.

## 0.5.0
- Create Deeplink Redirect feature.
  - Support an async redirect function.
  - Call `redirect(label, url)` to navigate to another page.
- Fix incorrect null group comparison breaking navigation.

## 0.4.1 
- Create NavigationData `group` parameter to support mapping different URLs to a single page.

## 0.4.0
- Update Flutter v3.16.9.
- Add documentation for `NavigationManager` functions.
- Create pop `inclusive`. Support popping the page including itself.
- Create `removeAbove` function to support removing a page above another page.
- Create `ShouldNavigateDeeplinkFunction` callback parameters. Adds support for conditional deeplink navigation logic based on the URL and query parameters.
- Fix missing `excludeDeeplinkNavigationPages`.
- Update example dependencies.

## 0.3.2
- Create `LifecycleObserverStateMixin` for StatefulWidgets.
- Update LifecycleObserverMixin with new `onHidden` lifecycle callback.
- Fix BuildContext disposed and mounted not checked.
- Create Lifecycle Callbacks Example.
- Document onRoutePause.

## 0.3.1
- Fix `NavigationListenerMixin` to return `onRouteResumed` correctly.
- Fix set URL as RouteSettings name instead of unformated path template.

## 0.3.0
- Create `pauseNavigation` and `resumeNavigation` methods. Use to defer handling navigation. 
  - Useful for showing a loading screen while fetching auth or app state during initialization.
- Create `setOverlay` and `removeOverlay` methods. Display a Page overlay on top of existing routes without changing the URL or navigation structure.
  - Useful for displaying a passcode or lock screen on top of all pages.
- Create `main_auth_delay.dart`, `main_initial_route.dart`, and `main_lock_screen.dart` examples.

## 0.2.1
- Add a new optional parameter `all` to the `pop` method. Pop `all` overrides the safety check that prevents removing all pages.
- Update usage of `popUntil` and `pushReplacementRoute` methods to use `all` parameter.
- Set initialRoute to the full URI instead of just the path in DefaultRouteInformationParser class.

## 0.2.0
- Update deprecated RouteInformation. Use Uri instead of location string.
- Fix add route empty check to all notify route changed calls.

## 0.1.9
- Fix crash when pushing onto empty stack. 

## 0.1.8
- Create navigation route updates for `NavigationManager.instance.getCurrentRoute` broadcast stream.
- Listen to route changes and updates with `NavigationManager.instance.getCurrentRoute.listen((DefaultRoute currentRoute) {});`

## 0.1.7
- Fix ability to push the same route with different query parameters.

## 0.1.6
- Update global data to support duplicate routes.

## 0.1.2
- Added support for pushing the same route with different path parameters.
- For example, pushing the same `ProjectPage` with different path parameters `/project/1`, `/project/2`, etc is now supported.

## 0.1.1
- Create `NavigationUtils.canOpenDeeplinkDestination`.
- Added a new parameter `push` to `NavigationUtils.openDeeplinkDestination` to override set backstack behavior and push destination directly.

## 0.1.0
- Initial Release.
