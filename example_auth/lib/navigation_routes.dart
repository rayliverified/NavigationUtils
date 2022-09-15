import 'package:example_auth/main.dart';
import 'package:example_auth/pages/auth/auth_components.dart';
import 'package:navigation_utils/navigation_utils.dart';

List<NavigationData> routes = [
  NavigationData(
      label: HomePage.name,
      url: '/',
      builder: (context, routeData, globalData) => const HomePage()),
  NavigationData(
      label: LoginForm.name,
      url: '/login',
      builder: (context, routeData, globalData) => const HomePage()),
  NavigationData(
      label: SignUpForm.name,
      url: '/signup',
      builder: (context, routeData, globalData) => const HomePage()),
  NavigationData(
      label: ResetPasswordForm.name,
      url: '/reset_password',
      builder: (context, routeData, globalData) => const HomePage()),
];
