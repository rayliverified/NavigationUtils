import 'dart:math';

import 'package:example_auth/ui/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:navigation_utils/navigation_utils.dart';

import 'auth_components.dart';

enum AuthPageType {
  login,
  signup,
  resetPassword,
}

class AuthPage extends StatefulWidget {
  final AuthPageType type;

  const AuthPage({super.key, required this.type});

  @override
  State<AuthPage> createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  bool get isLoginPage => widget.type == AuthPageType.login;

  bool get isSignupPage => widget.type == AuthPageType.signup;

  bool get isForgotPasswordPage => widget.type == AuthPageType.resetPassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.only(bottom: 48)),
                Text(
                  getPageTitle(widget.type),
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                LayoutBuilder(builder: (context, constraints) {
                  double width = min(420, constraints.maxWidth);
                  return Container(
                    width: width,
                    decoration: defaultShadow,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: getPage(widget.type),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: missing_return
  Widget getPage(AuthPageType type) {
    switch (type) {
      case AuthPageType.login:
        return LoginForm(
          onSignupTapped: () => NavigationManager.instance.routerDelegate
              .pushReplacement(SignUpForm.name),
          onResetPasswordTapped: () => NavigationManager.instance.routerDelegate
              .push(ResetPasswordForm.name),
        );
      case AuthPageType.signup:
        return SignUpForm(
            onLoginTapped: () => NavigationManager.instance.routerDelegate
                .pushReplacement(LoginForm.name));
      case AuthPageType.resetPassword:
        return ResetPasswordForm(
            onBackPressed: () =>
                NavigationManager.instance.routerDelegate.pop());
    }
  }

  // ignore: missing_return
  String getPageTitle(AuthPageType type) {
    switch (type) {
      case AuthPageType.login:
        return 'Login';
      case AuthPageType.signup:
        return 'Sign Up';
      case AuthPageType.resetPassword:
        return 'Forgot Password';
    }
  }
}
