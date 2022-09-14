import 'package:example_auth/main.dart';
import 'package:navigation_utils/navigation_utils.dart';

List<NavigationData> routes = [
  NavigationData(
      label: HomePage.name,
      url: '/',
      builder: (context, routeData, globalData) => const HomePage()),
];
