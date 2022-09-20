import 'dart:async';

import 'package:example_auth/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:navigation_utils/navigation_utils.dart';
import 'package:universal_io/io.dart';

import '../../services/auth_service.dart';
import '../../ui/buttons.dart';
import '../../ui/ui_constants.dart';
import '../../utils/string_validators.dart';
import '../../utils/value_response.dart';

class SignUpForm extends StatefulWidget {
  static const String name = 'signup';

  final Function? onLoginTapped;

  const SignUpForm({super.key, this.onLoginTapped});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final FocusScopeNode _node = FocusScopeNode();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String email = '';
  String password = '';
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool submitted = false;

  String? errorMessage;
  String? googleErrorMessage;

  @override
  void dispose() {
    _node.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> signupSubmit() async {
    if (!emailIsValid(_emailController.text) ||
        !passwordIsValid(_passwordController.text)) {
      submitted = true;
      setState(() {});
      return;
    }

    submitted = true;
    isLoading = true;
    errorMessage = null;
    setState(() {});

    final ValueResponse response = await GetIt.instance
        .get<AuthServiceBase>()
        .registerWithEmailAndPassword(
            '', _emailController.text, _passwordController.text);

    // The login and signup forms look very similar.
    // It is common to try to login through the signup form.
    // If the email exists, try to login user with credential automatically.
    if (!response.isSuccess &&
        (response.error.message.contains('EMAIL_EXISTS') ||
            response.error.code.contains('email-already-in-use'))) {
      final ValueResponse<void> loginResult = await GetIt.instance
          .get<AuthServiceBase>()
          .signInWithEmailAndPassword(
            _emailController.text,
            _passwordController.text,
          );
      // If login was successful, finish loading.
      // Otherwise, return EMAIL_EXISTS error.
      isLoading = false;
      if (loginResult.isSuccess) {
        TextInput.finishAutofillContext();
        NavigationManager.instance.routerDelegate.set([HomePage.name]);
        return;
      }
    }

    isLoading = false;

    if (response.isSuccess) {
      TextInput.finishAutofillContext();
      NavigationManager.instance.routerDelegate.set([HomePage.name]);
      return;
    } else {
      errorMessage = response.error.message;
    }
    if (mounted) setState(() {});
  }

  Future<void> loginWithGoogle() async {
    submitted = true;
    isGoogleLoading = true;
    googleErrorMessage = null;
    setState(() {});
    final AuthResult result = await (GetIt.instance
        .get<AuthServiceBase>()
        .googleSignIn() as FutureOr<AuthResult>);

    isGoogleLoading = false;

    if (result.success) {
      NavigationManager.instance.routerDelegate.set([HomePage.name]);
      return;
    } else {
      googleErrorMessage = result.errorMessage;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _node,
      child: Form(
        onChanged: () {
          email = _emailController.text;
          password = _passwordController.text;
          setState(() {});
        },
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _EmailField(
                controller: _emailController,
                submitted: submitted,
                isLoading: isLoading,
                focusNode: _node,
                onEditingComplete: _node.nextFocus,
              ),
              const Padding(padding: EdgeInsets.only(bottom: 16)),
              _PasswordField(
                controller: _passwordController,
                isLoading: isLoading,
                onSubmit: (_) => signupSubmit(),
                submitted: submitted,
                autofillHints: const [AutofillHints.newPassword],
                labelText: 'Password',
              ),
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.fastOutSlowIn,
                child: errorMessage != null
                    ? Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              LoadingButton(
                title: 'Sign up',
                borderRadius: buttonRadiusValue,
                onPressed: signupSubmit,
                isLoading: isLoading,
              ),
              const Padding(padding: EdgeInsets.only(bottom: 24)),
              if (kIsWeb || Platform.isWindows == false) ...[
                const OrDivider(dividerLength: 160),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  child: googleErrorMessage != null
                      ? Text(
                          googleErrorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                GoogleLoginButton(
                  isLoading: isGoogleLoading,
                  onPressed: loginWithGoogle,
                ),
                const Padding(padding: EdgeInsets.only(bottom: 24)),
              ],
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    TextSpan(
                      text: 'Login',
                      style: Theme.of(context).textTheme.bodyText1!.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = widget.onLoginTapped as void Function()?,
                    ),
                  ],
                ),
              ),
              const Padding(padding: EdgeInsets.only(bottom: 16)),
              const TermsAndConditionsText(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  static const String name = 'login';

  final Function? onSignupTapped;
  final Function? onResetPasswordTapped;

  const LoginForm({super.key, this.onSignupTapped, this.onResetPasswordTapped});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final FocusScopeNode _node = FocusScopeNode();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String email = '';
  String password = '';
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool submitted = false;

  String? errorMessage;
  String? googleErrorMessage;

  @override
  void dispose() {
    _node.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> loginSubmit() async {
    if (emailIsValid(_emailController.text) == false ||
        passwordIsValid(_passwordController.text) == false) {
      submitted = true;
      setState(() {});
      return;
    }

    submitted = true;
    isLoading = true;
    errorMessage = null;
    setState(() {});

    final ValueResponse<void> result = await GetIt.instance
        .get<AuthServiceBase>()
        .signInWithEmailAndPassword(
            _emailController.text, _passwordController.text);

    isLoading = false;
    if (result.isSuccess) {
      TextInput.finishAutofillContext();
      NavigationManager.instance.routerDelegate.set([HomePage.name]);
      return;
    } else {
      errorMessage = result.error.message;
    }
    if (mounted) setState(() {});
  }

  Future<void> loginWithGoogle() async {
    submitted = true;
    isGoogleLoading = true;
    googleErrorMessage = null;
    setState(() {});
    final AuthResult result = await (GetIt.instance
        .get<AuthServiceBase>()
        .googleSignIn() as FutureOr<AuthResult>);

    isGoogleLoading = false;

    if (result.success) {
      NavigationManager.instance.routerDelegate.set([HomePage.name]);
      return;
    } else {
      googleErrorMessage = result.errorMessage;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _node,
      child: Form(
        onChanged: () {
          email = _emailController.text;
          password = _passwordController.text;
          setState(() {});
        },
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _EmailField(
                controller: _emailController,
                submitted: submitted,
                isLoading: isLoading,
                onEditingComplete: _node.nextFocus,
              ),
              const Padding(padding: EdgeInsets.only(bottom: 16)),
              _PasswordField(
                controller: _passwordController,
                labelText: 'Password',
                submitted: submitted,
                isLoading: isLoading,
                onSubmit: (_) => loginSubmit(),
              ),
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.fastOutSlowIn,
                child: errorMessage != null
                    ? Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              LoadingButton(
                isLoading: isLoading,
                title: 'Login',
                borderRadius: buttonRadiusValue,
                onPressed: loginSubmit,
              ),
              const SizedBox(height: 24),
              if (kIsWeb || Platform.isWindows == false) ...[
                const OrDivider(dividerLength: 160),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  child: googleErrorMessage != null
                      ? Text(
                          googleErrorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                GoogleLoginButton(
                  isLoading: isGoogleLoading,
                  onPressed: loginWithGoogle,
                ),
                const SizedBox(height: 24),
              ],
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Need an account? ',
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    TextSpan(
                      text: 'Register',
                      style: Theme.of(context).textTheme.bodyText1!.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = widget.onSignupTapped as void Function()?,
                    ),
                  ],
                ),
              ),
              const Padding(padding: EdgeInsets.only(bottom: 24)),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'Forgot your password?',
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(
                      color: Colors.blue, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()
                    ..onTap = widget.onResetPasswordTapped as void Function()?,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResetPasswordForm extends StatefulWidget {
  static const String name = 'reset_password';

  final Function? onBackPressed;

  const ResetPasswordForm({super.key, this.onBackPressed});

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final FocusScopeNode _node = FocusScopeNode();
  final TextEditingController _emailController = TextEditingController();

  String email = '';
  bool isLoading = false;
  bool submitted = false;

  @override
  void dispose() {
    _node.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (emailIsValid(_emailController.text) == false) {
      // Do not show the error pop up when empty.
      submitted = true;
      setState(() {});
      return;
    }

    submitted = true;
    isLoading = true;
    setState(() {});

    await GetIt.instance
        .get<AuthServiceBase>()
        .resetPassword(_emailController.text);

    isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _node,
      child: Form(
        onChanged: () {
          email = _emailController.text;
          setState(() {});
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _EmailField(
              controller: _emailController,
              submitted: submitted,
              isLoading: isLoading,
              onSubmit: (_) => resetPassword(),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 24)),
            LoadingButton(
              title: 'Reset password',
              isLoading: isLoading,
              borderRadius: 12,
              onPressed: resetPassword,
            ),
            const Padding(padding: EdgeInsets.only(bottom: 24)),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'Go back',
                style: Theme.of(context).textTheme.bodyText1!.copyWith(
                    color: Colors.blue, decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = widget.onBackPressed as void Function()?,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Check this for difference between [onSubmit] and [onEditingComplete]
/// https://stackoverflow.com/a/65172300/9199362
class _EmailField extends StatefulWidget {
  @override
  __EmailFieldState createState() => __EmailFieldState();

  final TextEditingController? controller;
  final bool? submitted;
  final bool? isLoading;
  final FocusNode? focusNode;
  final Function? onEditingComplete;
  final ValueChanged<String>? onSubmit;
  final TextInputAction textInputAction;

  const _EmailField({
    this.controller,
    this.submitted,
    this.isLoading,
    this.focusNode,
    this.onEditingComplete,
    this.onSubmit,
    this.textInputAction = TextInputAction.next,
  });
}

class __EmailFieldState extends State<_EmailField> {
  FocusNode focusNode = FocusNode();
  bool firstFocus = true;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        firstFocus = false;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  String? get errorText {
    final bool showErrorText =
        !firstFocus && !emailIsValid(widget.controller!.text);

    final String errorText = widget.controller!.text.isEmpty
        ? 'Email cannot be empty'
        : 'Email is invalid';
    return showErrorText ? errorText : null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        key: const Key('email'),
        controller: widget.controller,
        focusNode: focusNode,
        validator: (value) => emailIsValid(value) == false ? errorText : null,
        autovalidateMode: (firstFocus == false)
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'your@email.com',
            errorText: errorText,
            contentPadding: inputPaddingPlatformSpecific()),
        autocorrect: false,
        autofillHints: const [AutofillHints.email, AutofillHints.username],
        textInputAction: widget.textInputAction,
        keyboardType: TextInputType.emailAddress,
        onEditingComplete: widget.onEditingComplete as void Function()?,
        onFieldSubmitted: widget.onSubmit,
        inputFormatters: <TextInputFormatter>[
          emailInputFormatter,
        ]);
  }
}

/// Check this for difference between [onSubmit] and [onEditingComplete]
/// https://stackoverflow.com/a/65172300/9199362
class _PasswordField extends StatefulWidget {
  @override
  __PasswordFieldState createState() => __PasswordFieldState();

  final TextEditingController? controller;
  final String? labelText;
  final bool? submitted;
  final bool? isLoading;
  final FocusNode? focusNode;
  final Function? onEditingComplete;
  final ValueChanged<String>? onSubmit;
  final TextInputAction textInputAction;
  final List<String> autofillHints;

  const _PasswordField({
    this.controller,
    this.labelText,
    this.submitted,
    this.isLoading,
    this.focusNode,
    this.onEditingComplete,
    this.onSubmit,
    this.autofillHints = const [AutofillHints.password],
    this.textInputAction = TextInputAction.done,
  });
}

class __PasswordFieldState extends State<_PasswordField> {
  FocusNode focusNode = FocusNode();
  bool firstFocus = true;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        firstFocus = false;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  String? get errorText {
    final bool showErrorText =
        !firstFocus && !passwordIsValid(widget.controller!.text);

    final String errorText = widget.controller!.text.isEmpty
        ? 'Password cannot be empty'
        : 'Password is too short';
    return showErrorText ? errorText : null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        key: const Key('password'),
        controller: widget.controller,
        focusNode: focusNode,
        validator: (value) =>
            passwordIsValid(value) == false ? errorText : null,
        autovalidateMode: (firstFocus == false)
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        decoration: InputDecoration(
            labelText: widget.labelText,
            errorText: errorText,
            contentPadding: inputPaddingPlatformSpecific()),
        obscureText: true,
        autocorrect: false,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmit,
        onEditingComplete: widget.onEditingComplete as void Function()?);
  }
}

// TODO: Moved to `ui/buttons.dart`
// class LoadingButton extends StatelessWidget {
//   final String title;
//   final bool isLoading;
//   final Function onPressed;
//   final double borderRadius;

//   const LoadingButton({
//     this.title,
//     this.isLoading,
//     this.onPressed,
//     this.borderRadius,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton.icon(
//         onPressed: isLoading ? null : onPressed,
//         style: ElevatedButton.styleFrom(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.all(buttonRadius),
//           ),
//           padding: const EdgeInsets.symmetric(vertical: 20),
//           elevation: 0,
//           textStyle: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         icon: isLoading
//             ? Container(
//                 width: 26,
//                 height: 20,
//                 padding: EdgeInsets.only(right: 6),
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               )
//             : SizedBox(height: 24),
//         label: Text(title));
//   }
// }

class GoogleLoginButton extends StatelessWidget {
  final bool? isLoading;
  final Function? onPressed;

  const GoogleLoginButton({
    super.key,
    this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
          padding: buttonPaddingPlatformSpecific(),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          textStyle: Theme.of(context).textTheme.button,
        ),
        icon: isLoading!
            ? const SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : const Image(
                image: AssetImage('assets/images/google_logo.png'),
                width: 24,
                height: 24,
              ),
        label: const Text('Sign in with Google'),
        onPressed: isLoading! ? null : onPressed as void Function()?);
  }
}

class TermsAndConditionsText extends StatelessWidget {
  const TermsAndConditionsText({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'By creating an account, you accept \nour ',
        style: Theme.of(context).textTheme.bodyText2,
        children: [
          TextSpan(
              text: 'Terms and Conditions',
              style: Theme.of(context).textTheme.bodyText2!.copyWith(
                  color: Colors.blue, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()..onTap = () {})
        ],
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  final double dividerLength;
  final double? thickness;
  final TextStyle? style;

  const OrDivider(
      {super.key, this.dividerLength = 120, this.thickness, this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: dividerLength / 2,
          child: Divider(
              color: const Color(0xFFDFDFDF),
              height: 2,
              thickness: thickness ?? 2),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: style ??
                Theme.of(context)
                    .textTheme
                    .bodyText2!
                    .copyWith(color: const Color(0xFFB4B4B4)),
          ),
        ),
        SizedBox(
          width: dividerLength / 2,
          child: Divider(
              color: const Color(0xFFDFDFDF),
              height: 2,
              thickness: thickness ?? 2),
        ),
      ],
    );
  }
}
