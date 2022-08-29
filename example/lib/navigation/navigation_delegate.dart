// import 'package:flutter/widgets.dart';
// import 'package:navigation_utils/navigation_utils.dart';
//
// import 'navigation_routes.dart';
//
// class CustomRouterDelegate extends DefaultRouterDelegate {
//   @override
//   List<NavigationData> namedRoutes = myNamedRoutes;
//
//   @override
//   bool debugLog = true;
//
//   CustomRouterDelegate();
//
//   @override
//   Widget build(BuildContext context) {
//     return Navigator(
//       key: navigatorKey,
//       pages: [
//         ...NavigationBuilder(
//           routeDataList: mainRoutes,
//           routes: myNamedRoutes,
//         ).build(context),
//       ],
//       onPopPage: (route, result) {
//         debugPrint('Pop Page');
//         if (!route.didPop(result)) {
//           return false;
//         }
//         if (canPop) {
//           pop(result);
//         }
//         return true;
//       },
//       observers: [],
//     );
//   }
// }
