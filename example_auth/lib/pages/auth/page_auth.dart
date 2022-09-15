import 'dart:math';

import 'package:example_auth/ui/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:navigation_utils/navigation_utils.dart';
import 'package:provider/provider.dart';

import 'auth_components.dart';

enum AuthPageType {
  login,
  signup,
  resetPassword,
}

class AuthPageWrapper extends StatelessWidget {
  final AuthPageType type;

  const AuthPageWrapper({super.key, this.type = AuthPageType.signup});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthPageModelBase>(
        create: (context) => AuthPageModel(context, type),
        child: const AuthPage());
  }
}

abstract class AuthPageModelBase with ChangeNotifier {
  BuildContext context;
  AuthPageType type;

  AuthPageModelBase(this.context, this.type);

  bool get isLoginPage => type == AuthPageType.login;

  bool get isSignupPage => type == AuthPageType.signup;

  bool get isForgotPasswordPage => type == AuthPageType.resetPassword;

  void setAuthPageType(AuthPageType type) =>
      throw UnimplementedError('Use Implementation');
}

class AuthPageModel extends AuthPageModelBase {
  AuthPageModel(super.context, super.type);

  @override
  void setAuthPageType(AuthPageType type) {
    AuthPageType previousType = type;
    switch (previousType) {
      case AuthPageType.login:
        break;
      case AuthPageType.signup:
        break;
      case AuthPageType.resetPassword:
        break;
    }

    this.type = type;
    switch (type) {
      case AuthPageType.login:
        NavigationManager.instance.routerDelegate.push(LoginForm.name);
        break;
      case AuthPageType.signup:
        NavigationManager.instance.routerDelegate.push(SignUpForm.name);
        break;
      case AuthPageType.resetPassword:
        NavigationManager.instance.routerDelegate.push(ResetPasswordForm.name);
        break;
    }

    notifyListeners();
  }
}

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthPageModelBase>(builder: (context, model, child) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.only(bottom: 48)),
                Text(
                  getPageTitle(model),
                  style: Theme.of(context).textTheme.headline1,
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
                    child: getPage(model),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ignore: missing_return
  Widget getPage(AuthPageModelBase model) {
    switch (model.type) {
      case AuthPageType.login:
        return LoginForm(
          onSignupTapped: () => model.setAuthPageType(AuthPageType.signup),
          onResetPasswordTapped: () =>
              model.setAuthPageType(AuthPageType.resetPassword),
        );
      case AuthPageType.signup:
        return SignUpForm(
            onLoginTapped: () => model.setAuthPageType(AuthPageType.login));
      case AuthPageType.resetPassword:
        return ResetPasswordForm(
            onBackPressed: () => model.setAuthPageType(AuthPageType.login));
    }
  }

  // ignore: missing_return
  String getPageTitle(AuthPageModelBase model) {
    switch (model.type) {
      case AuthPageType.login:
        return 'Login';
      case AuthPageType.signup:
        return 'Sign Up';
      case AuthPageType.resetPassword:
        return 'Forgot Password';
    }
  }
}
