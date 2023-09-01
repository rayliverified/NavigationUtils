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