import 'package:navigation_utils/navigation_utils.dart';

import '../main.dart';

List<NavigationData> namedRoutes = [
  NavigationData(
      label: MyHomePage.name,
      url: '/',
      builder: (context, routeData, globalData) =>
          const MyHomePage(title: 'Navigation')),
];
