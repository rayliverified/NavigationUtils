import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:universal_io/io.dart';

import '../models/model_user.dart';
import '../utils/value_response.dart';
import 'auth_exceptions.dart';
import 'debug_logger.dart';
import 'user_manager.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;

  AuthResult._({required this.success, this.errorMessage});

  factory AuthResult.success() => AuthResult._(success: true);

  factory AuthResult.failure([String errorMessage = '']) =>
      AuthResult._(success: false, errorMessage: errorMessage);
}

class AuthService implements Disposable {
  static const String name = 'AuthService';

  static AuthService? _instance;

  static AuthService get instance {
    if (_instance == null) {
      DebugLogger.instance.printFunction('AuthService Initialized', name: name);
      // An instance persists the AuthService.
      _instance ??= AuthService._();
      return _instance!;
    }
    return _instance!;
  }

  late Stream<User?> firebaseAuthUserStream;
  late StreamSubscription firebaseAuthListener;

  ValueNotifier<bool> isAuthenticated = ValueNotifier(false);

  Function(String uid)? onUserAuthenticatedCallback;
  Function? onUserUnauthenticatedCallback;

  AuthService._() {
    // Note: Listeners  are put in the initialization call to avoid the Hot Restart stream duplication bug.
    // If any listener code is changed, a clean start is required.
    firebaseAuthUserStream =
        FirebaseAuth.instance.authStateChanges().asBroadcastStream();
    firebaseAuthListener = FirebaseAuth.instance
        .authStateChanges()
        .asBroadcastStream()
        .listen((user) {
      DebugLogger.instance.printFunction('authStateChanges: $user', name: name);
      if (user != null) {
        DebugLogger.instance
            .printFunction('onUserAuthenticated ${user.uid}', name: name);
        isAuthenticated.value = true;
        UserManager.instance.startUserStreamSubscription(user.uid);
        onUserAuthenticatedCallback?.call(user.uid);
      } else if (UserManager.instance.user.value.id.isNotEmpty) {
        // If UserModel exists, app is authenticated. Firebase Auth will return authenticated in a bit.
      } else {
        DebugLogger.instance.printFunction('onUserUnauthenticated', name: name);
        isAuthenticated.value = false;
        onUserUnauthenticatedCallback?.call();
      }
    });
  }

  Future<AuthService> init() async {
    DebugLogger.instance.printFunction('AuthService init', name: name);
    UserModel? userModel = await UserManager.instance.loadUserModelLocal();
    isAuthenticated.value = (userModel != null);
    return this;
  }

  @override
  FutureOr onDispose() {
    firebaseAuthListener.cancel();
    _instance = AuthService._();
  }

  /// An awaitable function that AuthService is initialized
  /// in the proper order on app startup.
  ///
  /// Internally, this function calls [loadUserModel]
  /// and returns the [AuthResult].
  ///
  /// FirebaseAuth's synchronous getter for auth state
  /// is not dependable on app initialization and will return
  /// unauthorized on certain app starts such as hot reload.
  /// Auth dependent functions should subscribe to
  /// [firebaseAuthListener].
  Future<AuthResult> initAuthState() async {
    DebugLogger.instance.printFunction('initAuthState', name: name);
    DebugLogger.instance
        .printInfo('Current User: ${FirebaseAuth.instance.currentUser?.uid}');
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // await fetchAndSetUserModel(uid);
      return AuthResult.success();
    }
    return AuthResult.failure();
  }

  // BEGIN: Firebase Auth Methods.
  /// Method to handle user sign in using email and password
  Future<ValueResponse<void>> signInWithEmailAndPassword(
      String email, String password) async {
    DebugLogger.instance
        .printFunction('signInWithEmailAndPassword', name: name);
    try {
      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user == null) {
        return ValueResponse.error('User not found');
      }

      final String uid = credential.user!.uid;
      await UserManager.instance.startUserStreamSubscription(uid);
    } on FirebaseAuthException catch (e) {
      return ValueResponse.exception(e.toException());
    }

    return ValueResponse.success();
  }

  /// User registration using email and password
  Future<ValueResponse<void>> registerWithEmailAndPassword(
      String name, String email, String password) async {
    DebugLogger.instance.printFunction(
        'registerWithEmailAndPassword: $name, $email, $password',
        name: name);
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final UserModel firebaseUser = UserModel(
        email: userCredential.user?.email ?? email,
        id: userCredential.user?.uid ?? '',
        photoUrl: userCredential.user?.photoURL ?? '',
        name: userCredential.user?.displayName ?? '',
      );
      UserModel? userModelHolder =
          await UserManager.instance.createUserModel(firebaseUser);
      if (userModelHolder == null) {
        return ValueResponse.error('Error: unable to create user.');
      }
      await UserManager.instance
          .startUserStreamSubscription(userCredential.user?.uid ?? '');
      return ValueResponse.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.toString()}');
      return ValueResponse.exception(e.toException());
    } on AuthException catch (e) {
      debugPrint('AuthException: ${e.toString()}');
      return ValueResponse.exception(
          ExceptionWrapper(e.message ?? e.toString()));
    }
  }

  /// Password reset email
  Future<ValueResponse<void>> sendPasswordResetEmail(String email) async {
    DebugLogger.instance
        .printFunction('sendPasswordResetEmail: $email', name: name);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      return ValueResponse.exception(e.toException());
    }

    return ValueResponse.success();
  }

  /// Sign out user from Firebase Auth.
  Future<void> signOut() async {
    DebugLogger.instance.printFunction('signOut', name: name);

    /// Clear user data.
    await UserManager.instance.resetUserModel();
    await UserManager.instance.onDispose();
    await FirebaseAuth.instance.signOut();
  }

  /// Sign in with Google.
  Future<AuthResult> googleSignIn() async {
    DebugLogger.instance.printFunction('googleSignIn', name: name);

    try {
      UserCredential? userCredential;
      // Firebase Auth now manages auth internally with `signInWithPopup`.
      // Web auth no longer requires the `google_signin` plugin.
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();

        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        if (Platform.isWindows) {
          // Default is a MissingPluginException error.
          return AuthResult.failure(
              'Sign in with Google is not yet supported on Windows');
        }
        GoogleSignInAccount? googleSignInAccount =
            await GoogleSignIn().signIn();
        if (googleSignInAccount == null) {
          return AuthResult.failure('Sign in canceled.');
        }
        GoogleSignInAuthentication googleAuth =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (userCredential.user == null) {
        return AuthResult.failure('User credential missing.');
      }
      UserModel user = UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        name: userCredential.user!.displayName ?? '',
        photoUrl: userCredential.user!.photoURL ?? '',
      );
      // When auth returns a null user, an AuthException is thrown.
      // This failure return is just for a null check.
      if (user.id.isEmpty) return AuthResult.failure('Unable to sign in.');
      // Google auth does not differentiate between
      // login and signup. Check to see if user is already created.
      final ValueResponse<UserModel> response =
          await UserManager.instance.fetchUserModel(user.id);
      if (response.isError) {
        // User is not created
        UserModel? userModel = await UserManager.instance.createUserModel(user);
        if (userModel == null) {
          return AuthResult.failure('Error: unable to create user.');
        }
      }
      await UserManager.instance.startUserStreamSubscription(user.id);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.toString()}');
      return AuthResult.failure(e.toString());
    } on Exception catch (e) {
      debugPrint('Exception: ${e.toString()}');
      return AuthResult.failure(e.toString());
    }
  }
  // END: Firebase Auth Methods.
}

/* Not currently used functions for managing
google, apple and anonymous signin
https://github.com/fireship-io/flutter-firebase-quizapp-course
final GoogleSignIn _googleSignIn = GoogleSignIn();
// Determine if Apple Signin is available on device
  Future<bool> get appleSignInAvailable => AppleSignIn.isAvailable();
  /// Sign in with Apple
  Future<FirebaseUser> appleSignIn() async {
    try {
      final AuthorizationResult appleResult =
          await AppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);
      if (appleResult.error != null) {
        // handle errors from Apple
      }
      final AuthCredential credential =
          OAuthProvider(providerId: 'apple.com').getCredential(
        accessToken:
            String.fromCharCodes(appleResult.credential.authorizationCode),
        idToken: String.fromCharCodes(appleResult.credential.identityToken),
      );
      AuthResult firebaseResult = await _auth.signInWithCredential(credential);
      FirebaseUser user = firebaseResult.user;
      // Update user data
      updateUserData(user);
      return user;
    } catch (error) {
      print(error);
      return null;
    }
  }
  /// Anonymous Firebase login
  Future<FirebaseUser> anonLogin() async {
    AuthResult result = await _auth.signInAnonymously();
    FirebaseUser user = result.user;
    updateUserData(user);
    return user;
  }
    /// Updates the User's data in Firestore on each new login
  Future<void> updateUserData(FirebaseUser user) {
    DocumentReference reportRef = _db.collection('reports').document(user.uid);
    return reportRef.setData({'uid': user.uid, 'lastActivity': DateTime.now()},
        merge: true);
  }

 */
