import 'package:example_auth/main.dart';
import 'package:example_auth/pages/auth/auth_components.dart';
import 'package:example_auth/pages/auth/page_auth.dart';
import 'package:navigation_utils/navigation_utils.dart';

List<NavigationData> routes = [
  NavigationData(
      label: HomePage.name,
      url: '/',
      builder: (context, routeData, globalData) => const HomePage(),
      metadata: {'auth': true}),
  NavigationData(
      label: LoginForm.name,
      url: '/login',
      builder: (context, routeData, globalData) =>
          const AuthPage(type: AuthPageType.login),
      metadata: {'type': 'auth'}),
  NavigationData(
      label: SignUpForm.name,
      url: '/signup',
      builder: (context, routeData, globalData) =>
          const AuthPage(type: AuthPageType.signup),
      metadata: {'type': 'auth'}),
  NavigationData(
      label: ResetPasswordForm.name,
      url: '/reset_password',
      builder: (context, routeData, globalData) =>
          const AuthPage(type: AuthPageType.resetPassword)),
];
