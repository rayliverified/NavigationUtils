# Navigation Utils
[![Pub release](https://img.shields.io/pub/v/navigation_utils.svg?style=flat-square)](https://pub.dev/packages/navigation_utils) [![GitHub Release Date](https://img.shields.io/github/release-date/searchy2/NavigationUtils.svg?style=flat-square)](https://github.com/searchy2/NavigationUtils) [![GitHub issues](https://img.shields.io/github/issues/searchy2/NavigationUtils.svg?style=flat-square)](https://github.com/searchy2/NavigationUtils/issues) [![GitHub top language](https://img.shields.io/github/languages/top/searchy2/NavigationUtils.svg?style=flat-square)](https://github.com/searchy2/NavigationUtils) [![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/searchy2/NavigationUtils.svg?style=flat-square)](https://github.com/searchy2/NavigationUtils) [![Libraries.io for GitHub](https://img.shields.io/librariesio/github/searchy2/NavigationUtils.svg?style=flat-square)](https://libraries.io/github/searchy2/NavigationUtils) [![License](https://img.shields.io/badge/License-BSD%200--Clause-orange.svg?style=flat-square)](https://opensource.org/licenses/0BSD)

> ### The missing navigation library for Navigator 2. 

NavigationUtils is a comprehensive package that simplifies the process of integrating Flutter's Navigator 2 into your applications. 

### Features

- Reimplements the Navigator 1 API in Navigator 2, including `push()`, `pop()`, `pushAndReplace()` and more.
- Full control over the navigation back stack through `set()`.
- Named route functionality with `pushNamed()`, `setNamed()`.
- Path-based routing support.
- Convenient functions for setting the URL and query parameters.

### Should I use Navigation Utils?

Use NavigationUtils if the existing Navigation Libraries aren't working for you and you need full control over the backstack.

- ❌ DON'T USE NavigationUtils if an existing navigation library works for you (GoRouter, RouteMaster, etc).
- ✅ USE NavigationUtils if you're thinking about implementing Navigator 2 directly or writing your own Navigation library.

Here's a clear, helpful diagram for deciding whether NavigationUtils is the right fit for a project.

![Screenshots](packages/Use-Navigation-Utils-Decision-Diagram.png)

NavigationUtils does NOT add complexity. Instead, it embraces the intricacies of Navigator 2, providing a nuanced, comprehensive approach to implementing navigation.

A few compelling arguments for using Navigation Utils: 

- You're learning how to use Flutter's Navigator 2, not a third party library. The time you invest won't be wasted.
- You can implement complex navigation schemas without wrestling with the library.
- You can design navigation that seamlessly aligns with your app and architecture, rather than allowing navigation to dictate architectural choices.

As you incorporate more advanced navigation features, like deeplinks, authentication, and URLs, you'll likely encounter growing challenges and limitations that can drive up costs. There comes a point when direct, hands-on experience with Navigator 2 becomes crucial.

<p align="center">
<img src="packages/Navigation-Utils-Breakeven-Graph.png" width="600">
</p>

If navigation hurdles have become a constant in your development process, it's time to bite the bullet and master Navigator 2. The learning curve is steep, but the alternative is a seemingly endless cycle of issues, roadblocks, and limitations.

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
List<NavigationData> routes = [
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

## Navigation

NavigationUtils supports path, name, and Route object-based routing. You can directly access these navigation functions through `NavigationManager.instance`.

### Path

Path-based routing can be considered "absolute" routing as each URL path is unique. The path is also the URL shown in the address bar on Web.

```dart
NavigationManager.instance.routerDelegate.push('/projects');
```

### Named

Navigator 1's named route navigation. The name of the route is often defined in the respective page or component and used as a reference for navigation.

```dart
NavigationManager.instance.routerDelegate.push(ProjectsPage.name);
```

### Route Object

Navigation can also use the raw Route object. Here, a DefaultRoute object is created with the specified path, which is then passed to the navigation. This method is primarily used internally and for supporting partial migrations to this library.

```dart
NavigationManager.instance.routerDelegate.pushRoute(DefaultRoute(path: '/projects'));
```

