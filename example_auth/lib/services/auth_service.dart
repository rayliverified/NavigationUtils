/// AuthService V18 (20241006)
library;

import 'dart:async';

import 'package:example_auth/models/model_user.dart';
import 'package:example_auth/services/debug_logger.dart';
import 'package:example_auth/utils/value_response.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:universal_io/io.dart';

import 'user_manager.dart';

class AuthService {
  static const String name = 'AuthService';

  static AuthService? _instance;

  static AuthService get instance {
    if (_instance == null) {
      DebugLogger.instance.printFunction('AuthService Initialized', name: name);
      _instance ??= AuthService._();
      return _instance!;
    }
    return _instance!;
  }

  late StreamSubscription _firebaseAuthListener;

  /// Returns `onUserAuthenticated` and `onUserUnauthenticated` callbacks.
  ///
  /// If the returned `uid` is not null, the user is authenticated.
  /// If the returned `uid` is null, the user is unauthenticated.
  ///
  /// Important platform differences:
  /// On Windows, this stream emits twice. The first emission
  /// is always unauthenticated.
  Stream<String?> get firebaseAuthUserStream =>
      firebaseAuthUserStreamController.stream;
  late StreamController<String?> firebaseAuthUserStreamController;
  Stream<UserModel> get userCreatedStream => userCreatedStreamController.stream;
  late StreamController<UserModel> userCreatedStreamController;

  bool firebaseAuthInitialized = false;
  ValueNotifier<bool> isAuthenticated = ValueNotifier(false);

  AuthService._() {
    // Note: Listeners  are put in the initialization call to avoid the Hot Restart stream duplication bug.
    // If any listener code is changed, a clean start is required.
    firebaseAuthUserStreamController = StreamController<String?>.broadcast();
    userCreatedStreamController = StreamController<UserModel>.broadcast();
    _firebaseAuthListener = FirebaseAuth.instance
        .authStateChanges()
        .asBroadcastStream()
        .listen((user) async {
          DebugLogger.instance.printFunction(
            'authStateChanges: $user',
            name: name,
          );
          firebaseAuthInitialized = true;
          if (user != null) {
            DebugLogger.instance.printFunction(
              'onUserAuthenticated ${user.uid}',
              name: name,
            );
            await UserManager.instance.startUserStreamSubscription(user.uid);
            isAuthenticated.value = true;
            firebaseAuthUserStreamController.add(user.uid);
          } else if (UserManager.instance.user.value.id.isNotEmpty &&
              isAuthenticated.value == false) {
            // If UserModel exists, app is authenticated. Firebase Auth will return authenticated in a bit.
            DebugLogger.instance.printInfo(
              'Waiting for FirebaseAuth to authenticate...',
              name: name,
            );
            return;
          } else {
            DebugLogger.instance.printFunction(
              'onUserUnauthenticated',
              name: name,
            );
            isAuthenticated.value = false;
            firebaseAuthUserStreamController.add(null);
          }
        });
  }

  Future<AuthService> init() async {
    DebugLogger.instance.printFunction('init', name: name);
    await UserManager.instance.loadUserModelLocal();
    return this;
  }

  Future<void> dispose() async {
    _firebaseAuthListener.cancel();
    _instance = AuthService._();
  }

  /// Method to handle user sign in using email and password
  Future<ValueResponse<void>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    DebugLogger.instance.printFunction(
      'signInWithEmailAndPassword',
      name: name,
    );
    try {
      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user == null) {
        return ValueResponse.error('User not found');
      }

      final String uid = credential.user!.uid;
      await UserManager.instance.startUserStreamSubscription(uid);
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('FirebaseAuthException: ${e.toString()}');

      return ValueResponse.exception(
        ExceptionWrapper(
          e.message ?? 'An error has occurred.',
          stackTrace: stackTrace,
          code: e.code,
        ),
      );
    }

    return ValueResponse.success();
  }

  /// User registration using email and password
  Future<ValueResponse<void>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    DebugLogger.instance.printFunction(
      'registerWithEmailAndPassword',
      name: name,
    );
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final UserModel firebaseUser = UserModel(
        email: userCredential.user?.email ?? email,
        id: userCredential.user?.uid ?? '',
        photoUrl: userCredential.user?.photoURL ?? '',
        firstName: firstName ?? userCredential.user?.displayName,
        lastName: lastName,
      );
      UserModel? userModel = await UserManager.instance.createUserModel(
        firebaseUser,
      );
      if (userModel == null) {
        return ValueResponse.error('Error: unable to create user.');
      }
      userCreatedStreamController.add(userModel);
      return ValueResponse.success();
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('FirebaseAuthException: ${e.toString()}');

      return ValueResponse.exception(
        ExceptionWrapper(
          e.message ?? 'An error has occurred.',
          stackTrace: stackTrace,
          code: e.code,
        ),
      );
    } on Exception catch (e, stackTrace) {
      return ValueResponse.exception(
        ExceptionWrapper(e.toString(), stackTrace: stackTrace),
      );
    }
  }

  /// Password reset email
  Future<ValueResponse<void>> sendPasswordResetEmail(String email) async {
    DebugLogger.instance.printFunction(
      'sendPasswordResetEmail: $email',
      name: name,
    );
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('FirebaseAuthException: ${e.toString()}');

      return ValueResponse.exception(
        ExceptionWrapper(
          e.message ?? 'An error has occurred.',
          stackTrace: stackTrace,
          code: e.code,
        ),
      );
    }

    return ValueResponse.success();
  }

  /// Sign in with Google.
  Future<ValueResponse<UserModel?>> googleSignIn() async {
    DebugLogger.instance.printFunction('googleSignIn', name: name);

    try {
      UserCredential? userCredential;
      // Firebase Auth now manages auth internally with `signInWithPopup`.
      // Web auth no longer requires the `google_signin` plugin.
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
      } else {
        if (Platform.isWindows && !kIsWeb) {
          // Default is a MissingPluginException error.
          return ValueResponse.error(
            'Sign in with Google is not yet supported on Windows',
          );
        }
        GoogleSignInAccount googleSignInAccount =
            await GoogleSignIn.instance.authenticate();
        GoogleSignInAuthentication googleAuth =
            googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }
      if (userCredential.user == null) {
        return ValueResponse.error('User credential missing.');
      }
      UserModel user = UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        photoUrl: userCredential.user!.photoURL ?? '',
        firstName: userCredential.user!.displayName?.split(' ').first ?? '',
        lastName:
            userCredential.user!.displayName?.contains(' ') == true
                ? userCredential.user!.displayName!.split(' ').skip(1).join(' ')
                : '',
      );
      // When auth returns a null user, an AuthException is thrown.
      // This failure return is just for a null check.
      if (user.id.isEmpty) return ValueResponse.error('Unable to sign in.');
      // Google auth does not differentiate between
      // login and signup. Check to see if user is already created.
      final ValueResponse<UserModel> response = await UserManager.instance
          .fetchUserModel(user.id);
      if (response.isError) {
        // User is not created
        UserModel? userModel = await UserManager.instance.createUserModel(user);
        if (userModel == null) {
          return ValueResponse.error('Error: unable to create user.');
        }
        userCreatedStreamController.add(userModel);
        return ValueResponse.success(userModel);
      }

      await UserManager.instance.startUserStreamSubscription(user.id);
      return ValueResponse.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.toString()}');
      return ValueResponse.exceptionRaw(e);
    } on Exception catch (e) {
      debugPrint('Exception: ${e.toString()}');
      return ValueResponse.exceptionRaw(e);
    }
  }
}
