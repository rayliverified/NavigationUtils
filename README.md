# Navigation Utils
[![Pub release](https://img.shields.io/pub/v/navigation_utils.svg?style=flat-square)](https://pub.dev/packages/navigation_utils) [![GitHub Release Date](https://img.shields.io/github/release-date/rayliverified/NavigationUtils.svg?style=flat-square)](https://github.com/rayliverified/NavigationUtils) [![GitHub issues](https://img.shields.io/github/issues/rayliverified/NavigationUtils.svg?style=flat-square)](https://github.com/rayliverified/NavigationUtils/issues) [![GitHub top language](https://img.shields.io/github/languages/top/rayliverified/NavigationUtils.svg?style=flat-square)](https://github.com/rayliverified/NavigationUtils) [![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/rayliverified/NavigationUtils.svg?style=flat-square)](https://github.com/rayliverified/NavigationUtils) [![License](https://img.shields.io/badge/License-BSD%200--Clause-orange.svg?style=flat-square)](https://opensource.org/licenses/0BSD)

![Screenshots](packages/icon_navigation_utils_256x.png)

> ### The missing navigation library for Flutter's Navigator 2. 

NavigationUtils makes it easy to implement Navigator 2 in your Flutter app.

### Features

- Reimplements the Navigator 1 API in Navigator 2, including `push()`, `pop()`, `pushAndReplace()` and more.
- Full control over the navigation back stack through `set()`.
- Named route support with `pushNamed()`, `setNamed()`.
- Path-based routing support.
- Convenient functions for setting the URL and query parameters.

## Quickstart

### Initial App Routing Configuration

```dart
MaterialApp.router(
      title: 'Navigation Utils Demo',
      routerDelegate: NavigationManager.instance.routerDelegate,
      routeInformationParser: NavigationManager.instance.routeInformationParser,
    );
```

**Tip:** Navigator 2 utilizes `MaterialApp.router` and requires a `RouterDelegate` and `RouteInformationParser`. These components replace the `routes` and `onGenerateRoute` builders of Navigator 1.

The NavigationManager acts as a global singleton, serving as a dependency injector while holding references to the `RouterDelegate` and `RouteInformationParser`. See the customization section for more information on how to use your own dependency injection and custom navigation lifecycle management.

### Initialize NavigationManager

```dart
void main() {
  NavigationManager.init(
      mainRouterDelegate: DefaultRouterDelegate(navigationDataRoutes: routes),
      routeInformationParser: DefaultRouteInformationParser());
  runApp(const MyApp());
}

```

**Tip:** `DefaultRouterDelegate` and `DefaultRouteInformationParser` are convenience classes provided by this library to help you get up and running quickly. For more information on migrating an existing delegate or using a custom implementation, see the customization section.

### Define Routes

```dart
List<NavigationData> get routes => [
  NavigationData(
      url: '/',
      builder: (context, routeData, globalData) =>
          const MyHomePage()),
  NavigationData(
      label: ProjectsPage.name,
      url: '/projects',
      builder: (context, routeData, globalData) =>
          const ProjectsPage()),
];

```

**Note:** Each route requires a URL because `NavigationData` maps a URL to a specific page. The NavigationData model holds routing information that Flutter's navigator needs. For more insights on passing query parameters and using page constructors, see customization sections below.

`NavigationData` contains an optional `label` property to support named routing like in Navigator 1. Navigator 2 does not supported named routing out of the box so named routing is reimplemented. Here, `ProjectsPage.name` is a static constant defined in the ProjectPage widget.

```dart
class ProjectsPage extends StatefulWidget {
  static const String name = 'projects';
  
  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}
```

## Examples

For new users, see the quick 5 line setup at [example/lib/main.dart](example/lib/main.dart). 

For a full, production ready configuration similar to the one used by 10,000+ users in [Codelessly - A Flutter App and Website Builder](https://codelessly.com), see [example_auth/main.dart](https://github.com/rayliverified/NavigationUtils/blob/master/example_auth/lib/main.dart).

Features:
- Complete authentication flow with login/signup screens.
- Route guards for authenticated pages.
- Navigation sync with user auth.
- Deep link and URL parameter handling.
- Flutter Firebase Auth integration and issues solved.
- Working Firebase Auth example on all platforms. 
- Handling navigation during authentication state changes.
- Managing loading and initialization.

## Navigation

The NavigationData class in the NavigationUtils library is used to encapsulate all the necessary data for defining a route in your application. It provides an easy way to define and manage your routes.

```dart
NavigationData(
  label: ProjectPage.name,
  url: '/project',
  builder: (context, routeData, globalData) =>
      const ProjectPage(),
),
```

- `label`: An optional `String` for named navigation.
- `url`: A `String` that represents the URL for the route. This is used to match the incoming route. It must start with a '/'. 
- `builder`: A `NavigationPageFactory` object. It is a function that returns a `Page` widget. This builder is used to construct the page when the route is navigated to.
- `pageType`: An optional `PageType` enum that can be used to further customize the type of the page. The PageType can be `material`, `cupertino`, or `transparent`.
- `fullScreenDialog`: An optional `bool` that indicates whether the route is a full-screen modal dialog.
- `barrierColor`: An optional `Color` that specifies the color of the barrier that will appear behind the dialog. This is used only if `fullScreenDialog` is `true`.
- `metadata`: A `Map<String, dynamic>` that can hold any additional data you want to associate with the route.

### Usage

NavigationUtils supports path, name, and Route object-based routing. You can directly access these navigation functions through `NavigationManager.instance`.

### Path

Path-based routing can be considered "absolute" routing as each URL path is unique. The path is also the URL shown in the address bar on Web.

```dart
NavigationManager.instance.push('/projects');
```

### Named

Navigator 1's named route navigation. The name of the route is often defined in the respective page or component and used as a reference for navigation.

```dart
NavigationManager.instance.push(ProjectsPage.name);
```

### Route Object

Navigation can also use the raw Route object. Here, a DefaultRoute object is created with the specified path, which is then passed to the navigation. This method is primarily used internally and for supporting partial migrations to this library.

```dart
NavigationManager.instance.pushRoute(DefaultRoute(path: '/projects'));
```

## Routing Parameters

Navigator 2 does not support query parameters, path parameters, route guards, or non-serializable objects out of the box. The default `PageRoute` class only supports URLs and arguments.

Please read and understand the following information as it is crucial to understanding how Navigator 2 works.

**Important:**

- **Arguments are NOT query parameters or related to URL routing in any way. Arguments are an internal parameter used to pass data between pages from the Legacy Navigator 1 implementation.**
- **Navigator 2 uses the full URL string as a unique page identifier. By default it does not do any path processing or conform to expected URL routing logic or behavior. `/home` and `/home/` are treated as two distinct pages.**

Navigator 2's default URL handling behavior is very limited and wrong by default for web. NavigationUtils adds support for URL routing parameters by extending `PageRoute` with a `DefaultRoute` and building an abstraction layer called `NavigationData` on top.

### Query Parameters

Access query parameters via `routeData.queryParameters` in `NavigationData`. Query parameters are stored in a `Map<String, String>` where the key is the query parameter name and the value is the query parameter value.

#### Example

```dart
// Route Definition
NavigationData(
  label: ProjectPage.name,
  url: '/project',
  builder: (context, routeData, globalData) => ProjectPage(
    id: int.tryParse(routeData.queryParameters['id'] ?? ''),
  ),
)
    
// Route Navigation
NavigationManager.instance.push(ProjectPage.name);
NavigationManager.instance.push(ProjectPage.name, queryParameters: {'id': '320'});
NavigationManager.instance.push('/project');
NavigationManager.instance.push('/project', queryParameters: {'id': '320'});
```

`ProjectPage` is mapped to the URL (`'/project'`). An `id` query parameter is used to pass the ID of the project. 

**Note:** All URL parameters are passed as Strings. This is because URLs are not "typed" and Strings by default.

- Extract `ints` and `doubles` with `int.tryParse` and `double.tryParse`.
- Extract `bools` with `routeData.queryParameters[variable] == 'true'` where the value passed in the URL is a `true` or `false` String.

#### Implementation Details

Navigator 2 does not support query parameters "out of the box" as the Navigator 2 API does not have a `query parameter` field. By default, Navigator 2 treats query parameters as part of the URL string and different query parameters as unique pages.

For example, all of the below home `/` URLs are treated as different pages by Navigator 2:

```
/
/?tab=community_page
/?tab=community_page&post=80
/?tab=message_page
/?referrer=google_ads
```

This is a problem because all of the URLs should point to the same page and query parameters should be passed to that page. To support query parameters properly, this library strips query parameters from URLs, stores them, and then rebundles them during the route construction process.

Internally, this library extracts the query parameters (`tab` ) and stores it in the constructed `DefaultRoute` object, passing only the root `/` URL to the underlying Navigator 2 API.

Multiple `NavigationData` instances can be defined with different query parameters to handle various scenarios or variations of the same page, all pointing to the same destination.

### Path Parameters

Path parameters are used to capture dynamic parts of a URL's path. They are denoted by a colon (`:`) followed by a parameter name in the URL pattern. The corresponding values for each path parameter are extracted from the actual URL when a match is found.

Access path parameters via `routeData.pathParameters` in `NavigationData`. Path parameters are stored in a `Map<String, String>` where the key is the path parameter name and the value is the path parameter value.

#### Example

```dart
// Route definition
NavigationData(
  label: ProjectPage.name,
  url: '/project/:projectId',
  builder: (context, routeData, globalData) => ProjectPage(
      id: int.tryParse(routeData.pathParameters['projectId'] ?? ''),
    );
  },
)
    
// Route navigation
NavigationManager.instance.push(ProjectPage.name);
NavigationManager.instance.push(ProjectPage.name, pathParameters: {'projectId': 320});
NavigationManager.instance.push('/project/320');
# Invalid: NavigationManager.instance.push('/project'); /project and /project/320 are different URLs.
```

In the example above, the `ProjectPage` is associated with the URL pattern `'/project/:projectId'`. The value of `projectId` is extracted from the actual URL. These parameters are then used to construct the `ProjectPage` with the corresponding values.

Multiple `NavigationData` instances can be defined with different URL patterns and path parameters to handle various routes and dynamic parts of the URL path.

**Note:** Ensure that the URL patterns in the `NavigationData` instances match the actual URLs accurately to enable correct parameter extraction.

- `/project` and `/project/:projectId` are different URLs. To support both, define a `NavigationData(url: '/project')` and `NavigationData(url: '/project/:projectId')`.
- A trailing slash such as `/project/` does not pass a null ID to `/project/:projectId`. Instead, `/project/` is equivalent to `/project`.

### Passing Objects and Data Between Pages with GlobalData

Arbitrary data such as classes and non-serializable variables can be passed between pages with `globalData`. `globalData` can be used to pass anything between pages.

#### Example
```dart
// Route Navigation
PostModel postModel = PostModel();
NavigationManager.instance.push(PostPage.name, globalData: {'postModel': postModel});

NavigationData(
  label: PostPage.name,
  url: '/post',
  builder: (context, routeData, globalData) => ProjectPage(
      postModel: globalData['postModel']),
    );
  },
)
```

A `PostModel` is passed to `PostPage` via `globalData`. The `PostPage` widget can now load the Post UI immediately.

#### Accessing and Modifying `globalData`

Beyond its use during navigation, `globalData` can be accessed and modified at any point in your application at `NavigationManager.instance.routerDelegate.globalData`. This allows for setting data and configurations at anytime.

**Example:**
```dart
// Set or update data
NavigationManager.instance.routerDelegate.globalData['selected_variant'] = 'A';

// Access data
String variant = NavigationManager.instance.routerDelegate.globalData['selected_variant'];
```

**Note:** `globalData` is not bound to the page lifecycle so any variables set must be manually disposed. Any outdated variables will need to be explicitly cleared. Most of the time, opening a page will set and override the data so stale variables are not a concern.

**Note:** The URL of the page is used as the key for storing data.

## Deeplinks

A special feature of NavigationUtils is it supports *deeplinks as data* and defining them all *in a single list*. This is done by creating a list of `DeeplinkDestination` instances. 

```dart
List<DeeplinkDestination> deeplinkDestinations = [
  DeeplinkDestination(
    deeplinkUrl: '/deeplink/login',
    destinationLabel: LoginPage.name),
  DeeplinkDestination(
    deeplinkUrl: '/deeplink/signup',
    destinationLabel: SignUpPage.name),
```

Each `DeeplinkDestination` represents a unique deeplink within your application and includes properties such as `deeplinkUrl`, `destinationLabel`, and `destinationUrl` to define the behavior of the deeplink.

This approach offers several advantages:

- **Centralization**: By defining all deeplinks in one place, it becomes easier to manage and update them. You can quickly find, add, remove, or modify deeplinks as your application evolves.
- **Consistency**: Having a single list ensures that every deeplink is defined in a consistent way, making your codebase more maintainable.
- **Flexibility**: Since deeplinks are defined as data, you can dynamically generate, modify, or filter them based on your application's needs.

### Custom Deeplinks Behavior

```dart
DeeplinkDestination(
  deeplinkUrl: '/deeplink/login',
  destinationLabel: LoginPage.name,
  destinationUrl: '/login',
  backstack: [InitializationPage.name, StartPage.name],
  backstackRoutes: [InitializationRoute(), StartRoute()],
  excludeDeeplinkNavigationPages: [ForgotPassword.name],
  shouldNavigateDeeplinkFunction: () {
    if (AuthService.instance.isAuthenticated) return false;
    return true;
  },
  mapArgumentsFunction: (pathParameters, queryParameters) {
    // Remap or process path and query parameters.
    String referrerId = queryParameters['referrer'] ?? '';
    InstallReferrer.instance.setReferrerId(referrerId);

    return {'id': pathParameters['userId'] ?? ''};
  },
  runFunction: (pathParameters, queryParameters) async {
    // Arbitrary function call for handling deeplinks without doing navigation.
  },
  authenticationRequired: false,
)
```

- `deeplinkUrl`: A required property representing the deep link URL.
- `destinationLabel`: The named route destination of the deep link.
- `destinationUrl`: The URL route of the destination.
- `backstack` and `backstackRoutes`: Specify the route backstack to which the user should return when navigating away from the deep link. Only one of these can be set.
- `excludeDeeplinkNavigationPages`: A list of pages that should be excluded from deep link navigation.
- `shouldNavigateDeeplinkFunction`: A function that determines whether the deep link should be navigated.
- `mapPathParameterFunction`, `mapQueryParameterFunction`, `mapArgumentsFunction`, `mapGlobalDataFunction`: Optional functions that map path parameters, query parameters, arguments, and global data, respectively.
- `runFunction`: A function to support handling deeplinks without navigating, such as allowing deeplinks to trigger app functionality such as analytics, sharing data through social links, or showing a bottom sheet, without navigating to a new page. This function is also called after navigation completes, which allows for logic to be run after deeplink navigation is complete.
- `authenticationRequired`: A boolean indicating whether authentication is required to navigate the deeplink.

By providing these parameters, NavigationUtils gives you the flexibility to customize deeplink behavior to suit your application's specific needs. Contributors are welcome to open an issue and PR to add additional functionality that might be missing.

### Deeplinks Usage

NavigationUtils includes a convenience function called `NavigationUtils.openDeeplinkDestination` to process URIs and map them to deeplinks. Here is a sample implementation:

```dart
class DefaultRouteParser {
  static bool openDeeplink(Uri? uri) {
    return NavigationUtils.openDeeplinkDestination(
      deeplinkDestinations: deeplinkDestinations,
      routerDelegate: NavigationManager.instance.routerDelegate,
      uri: uri,
      authenticated: AuthService.instance.isAuthenticated,
      currentRoute:
          NavigationManager.instance.currentRoute,
      excludeDeeplinkNavigationPages: doNotNavigateDeeplinkPages,
    );
  }
}
```

- `uri`: The `Uri` object representing the deeplink that you want to open.

- `deeplinkDestinations`: The list of `DeeplinkDestination` instances that define the deeplinks within your application.

- `routerDelegate`: The `BaseRouterDelegate` instance that handles the actual navigation within your application.

- `deeplinkDestination`: An optional `DeeplinkDestination` instance that you want to open. If not provided, the method will try to find the matching destination in the `deeplinkDestinations` list using the `uri`.

- `authenticated`: A boolean value that indicates whether the user is authenticated. This is used when the `DeeplinkDestination` requires authentication. Defaults to `true`.

- `currentRoute`: An optional `DefaultRoute` instance that represents the current route of the application. This is used for checking if the current page is in the `excludeDeeplinkNavigationPages` list.

- `excludeDeeplinkNavigationPages`: A list of strings that represent the labels or paths of the routes that should be excluded from deeplink navigation. If the current route's label or path is in this list, the method will not perform the navigation.

- `redirectFunction`: Redirect to another route.

This method tries to find the matching `DeeplinkDestination` for the given `uri` and performs various checks before navigating to the destination. These checks include checking whether the user is authenticated (if required), whether the current route is in the excluded list, and whether a custom navigation function allows the navigation. After these checks, the method navigates to the destination and processes any path parameters, query parameters, arguments, and global data as defined by the `DeeplinkDestination`. Finally, the method updates the route stack using the `routerDelegate` and applies the changes. The method returns `true` if the navigation was successful, and `false` otherwise.

## Deeplink Redirect

Deeplinks can be redirected based on custom logic using the `redirectFunction`. The `redirectFunction` is used to handle deeplink redirections based on custom logic. It takes the current path and query parameters, applies the redirect logic, and determines whether to navigate to the original destination or to a different one.

#### Usage
Define the redirectFunction to specify the custom logic for redirections. The function is invoked with the current path and query parameters, along with a redirect callback to navigate to the new destination.

```dart
redirectFunction: (pathParameters, queryParameters, redirect) {
  if (pathParameters.containsKey('id') && queryParameters.containsKey('action')) {
    redirect(
      label: 'newDestination',
      pathParameters: {'id': pathParameters['id']!},
      queryParameters: {'action': queryParameters['action']!},
      globalData: {'additionalData': 'example'}
    );
    return Future.value(true);
  }
  return Future.value(false);
}
```

- `pathParameters`: A `Map<String, String>` containing the current path parameters.
- `queryParameters`: A `Map<String, String>` containing the current query parameters.
- `redirect`: The callback function to navigate to the new destination.

#### Return Value

The `redirectFunction` returns a `Future<bool>`. If the function returns `true`, the redirection is considered successful, and the navigation proceeds to the new destination. If it returns `false`, the navigation proceeds to the original destination.

## URL Aliases

For single page apps, sometimes different URLs should map to the same Route. This fundamentally goes against Flutter's 1 to 1 URL to Route mapping. To solve this problem, the `group` parameter in the `NavigationData` class allows different URLs to map to the same page.

#### Usage

Define the `group` parameter in `NavigationData` to group multiple routes under the same destination.

```dart
NavigationData(
  label: HomePage.name,
  url: '/',
  builder: (context, routeData, globalData) =>
      HomePage(tab: routeData.queryParameters['tab'] ?? CommunityPage.name),
  group: HomePage.name,
),
NavigationData(
  label: CommunityPage.name,
  url: '/community',
  builder: (context, routeData, globalData) =>
      HomePage(tab: CommunityPage.name),
  group: HomePage.name,
),
NavigationData(
  label: NewsPage.name,
  url: '/news',
  builder: (context, routeData, globalData) =>
      HomePage(tab: NewsPage.name),
  group: HomePage.name,
),
```

In this example, three different URLs (`'/'`, `'/community'`, and `'/news'`) are mapped to the same `HomePage`. This feature is particularly useful when you want multiple routes to lead to the same page while maintaining state and animations.

## Route Guards

#### Authentication

NavigationUtils supports the common "Authenticated" route guard through the `authenticationRequired` boolean. 

1. Annotate each `DeeplinkDestination` with `authenticationRequired`.
2. Pass the authentication state from your Authentication Service to `NavigationUtils.openDeeplinkDestination(authenticated: AuthService.instance.isAuthenticated)`.

#### Do Not Navigate Pages

When the user is on certain pages, such as the onboarding page, you may often want to disable deeplinks. NavigationUtils supports this behavior with `excludeDeeplinkNavigationPages`. 

1. Define the list of pages to exclude in `excludeDeeplinkNavigationPages`. This list accepts named routes and path routes.
2. Pass the current page to `currentRoute` like `currentRoute: NavigationManager.instance.currentRoute`.

#### Custom Route Guards

Setup Custom Route Guards by tagging `NavigationData` routes with custom `metadata`.

First, add custom tags to `NavigationData(label: PremiumMemberPage.name, url: '/premium_page', metadata: {kUserStatus: PREMIUM})`. Here, the `PremiumPage` is tagged with `kUserStatus` and requires a `PREMIUM` status to navigate.

```dart
if (NavigationManager.instance.routerDelegate
    .currentConfiguration?.metadata?['kUserStatus'] == PREMIUM) {
  DefaultRouteParser.openDeeplink(uri);
}
```

#### Async Route Guards

NavigationUtils supports route guards through the `shouldNavigateDeeplinkFunction` property of the `DeeplinkDestination` class. This function is called before navigating to the deeplink destination and can be used to prevent navigation based on certain conditions. For example, you can check if a user is authenticated before allowing navigation to a protected route.

### Async Navigation

NavigationUtils supports asynchronous navigation, allowing you to perform asynchronous tasks such as data fetching or authentication checks before navigating to a deeplink destination. This is facilitated by the fact that the `shouldNavigateDeeplinkFunction` can be an asynchronous function, meaning it can return a `Future<bool>` instead of a simple `bool`. This lets you perform any necessary async operations and delay navigation until those operations complete.

## Nested Navigation (BETA)

#### Nested Tabs

[Example](https://github.com/rayliverified/NavigationUtils/blob/master/example/lib/main_nested_tabs.dart)


## Custom Route Transition Animations

NavigationUtils allows you to customize route transitions both globally and on a per-page basis.

### Global Transitions

You can define a global transition that will be applied to all routes unless overridden by a local (per-page) transition. To set a global transition, create a custom `Page` class that defines the transition within its `createRoute` method using `PageRouteBuilder`.

```dart
// Define a Custom Page for your global transition
class ScaleTransitionPageBuilder extends Page {
  final Widget child;

  const ScaleTransitionPageBuilder({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Define your custom transition animation here
        return ScaleTransition(
          scale: animation,
          alignment: Alignment.center,
          child: child,
        );
      },
    );
  }
}

// Override pageBuilder
NavigationManager.init(
  mainRouterDelegate: DefaultRouterDelegate(
    navigationDataRoutes: routes,
    pageBuilder: ({
      key,
      name,
      child,
      routeData,
      globalData,
      arguments,
    }) =>
        ScaleTransitionPageBuilder(
          key: key,
          name: name,
          arguments: arguments,
          child: child,
        ),
  ),
  routeInformationParser: DefaultRouteInformationParser(),
);
```

This will override the default MaterialPage transition animation and apply a scale transition to all pages.

### Per-Page Transitions

To override the global transition for a specific route, create a custom `Page` class for that route and use the `pageBuilder` property in `NavigationData`:

```dart
// Define a custom Page for your per-page transition
class RightToLeftTransitionPage extends Page {
  final Widget child;

  const RightToLeftTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }
}

// Usage in NavigationData:
NavigationData(
  label: 'Details',
  url: '/details',
  builder: (context, routeData, globalData) => DetailsPage(),
  pageBuilder: ({key, name, child, routeData, globalData, arguments}) {
    return RightToLeftTransitionPage(
      key: key,
      name: name,
      arguments: arguments,
      child: child,
    );
  },
),
```

In this example, the `DetailsPage` will have a right-to-left slide transition, overriding any global transition.

### Disable Transition Animations

#### Globally

```dart
// Define a custom Page for no transition
class NoTransitionPage extends Page {
  final Widget child;

  const NoTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child, // No transition
    );
  }
}

// In your main app initialization:
NavigationManager.init(
  mainRouterDelegate: DefaultRouterDelegate(
    navigationDataRoutes: routes,
    pageBuilder: ({
      key,
      name,
      child,
      routeData,
      globalData,
      arguments,
    }) => NoTransitionPage(
      key: key,
      name: name,
      arguments: arguments,
      child: child,
    ),
  ),
  routeInformationParser: DefaultRouteInformationParser(),
);
```

#### Per-Page

To disable transitions for a specific page, use the `NoTransitionPage` within the `pageBuilder` of the corresponding `NavigationData`:

```dart
NavigationData(
  label: 'No Animation',
  url: '/no-animation',
  builder: (context, routeData, globalData) => NoAnimationPage(),
  pageBuilder: ({key, name, child, routeData, globalData, arguments}) {
    return NoTransitionPage(
      key: key,
      name: name,
      arguments: arguments,
      child: child,
    );
  },
),
```

You can create any custom transition effect you need by defining your own `Page` classes and using them either globally or on a per-page basis.

## Understanding Cache Behavior

NavigationUtils implements intelligent page caching to optimize performance and provide smooth navigation experiences. 

> **🎯 Unique Feature:** This caching system is exclusive to NavigationUtils. Flutter's Navigator 2 and popular libraries like go_router have a bug which causes significant performance issues when there are 5+ pages in the navigation stack as all pages get rebuilt on every navigation event. This works by default in Navigator 1, but requires special care due to opaque Navigator internal equality checks. NavigationUtils brings back this essential optimization by intelligently caching and reusing page instances.

The caching system automatically handles:

- **Grouped routes** that share widget instances (e.g., tab navigation)
- **Query parameter changes** that update pages instead of recreating them
- **Duplicate routes** that create separate instances when needed
- **State preservation** across navigation events

For a comprehensive guide on how cache keys are generated and managed, see [CACHE_BEHAVIOR.md](CACHE_BEHAVIOR.md).

### Key Behaviors

**Query Parameters Update Pages:**
```dart
push('/product?id=1');  // Creates page
push('/product?id=2');  // Updates same page with new data
```

**Grouped Routes Share Instances:**
```dart
NavigationData(url: '/', group: 'home'),
NavigationData(url: '/games', group: 'home'),
// Both share the same widget instance
```

**Duplicates Create New Instances:**
```dart
push('/item');  // First instance
push('/item');  // Second instance (separate page)
```

### Enabling Hot Reload for Routes

When developing, you may add or change routes and expect hot reload to pick up the updates. Unfortunately, hot reload does not work out of the box with Flutter's Navigator widget if it is static, which it needs to be to avoid recreating itself on every navigation event. To enable hot reload, add the following to your top level App widget.

```dart
@override
void reassemble() {
  NavigationManager.instance.routerDelegate.navigationDataRoutes = routes;
  super.reassemble();
}
```

**Why this works:**
In Flutter, hot reload only reloads the widget build path.
- Use a getter for `routes`, as top-level variables are not re-initialized on hot reload.
- Avoid `final` references so new instances can be created on hot reload.
- Update static `Navigator` internal variables.
