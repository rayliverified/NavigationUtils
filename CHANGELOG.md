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