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

class AuthPageWrapper extends StatefulWidget {
  final AuthPageType type;

  const AuthPageWrapper({Key? key, required this.type}) : super(key: key);

  @override
  State<AuthPageWrapper> createState() => _AuthPageWrapperState();
}

class _AuthPageWrapperState extends State<AuthPageWrapper> {
  late AuthPageModelBase authPageModelBase;

  @override
  void initState() {
    super.initState();
    authPageModelBase = AuthPageModel(context, widget.type);
  }

  @override
  void dispose() {
    authPageModelBase.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AuthPageWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    authPageModelBase.setAuthPageType(widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthPageModelBase>.value(
        value: authPageModelBase, child: const AuthPage());
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
    if (type == this.type) {
      return;
    }

    this.type = type;
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
                  style: Theme.of(context).textTheme.headline2,
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
