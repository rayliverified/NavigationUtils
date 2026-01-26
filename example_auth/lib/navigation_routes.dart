import 'package:navigation_utils/navigation_utils.dart';

import 'main.dart';
import 'pages/auth/auth_components.dart';
import 'pages/auth/page_auth.dart';

List<NavigationData> get routes => [
  NavigationData(
      label: HomePage.name,
      url: '/',
      builder: (context, routeData, globalData) => const HomePage(),
      metadata: {'auth': true}),
  NavigationData(
      label: LoginForm.name,
      url: '/login',
      group: 'auth',
      builder: (context, routeData, globalData) =>
          AuthPage(type: AuthPageType.login),
      metadata: {'type': 'auth'}),
  NavigationData(
      label: SignUpForm.name,
      url: '/signup',
      group: 'auth',
      builder: (context, routeData, globalData) =>
          AuthPage(type: AuthPageType.signup),
      metadata: {'type': 'auth'}),
  NavigationData(
      label: ResetPasswordForm.name,
      url: '/reset_password',
      group: 'auth',
      builder: (context, routeData, globalData) =>
          AuthPage(type: AuthPageType.resetPassword)),
];
