import 'dart:convert';

import 'package:example_auth/utils/value_response.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  final String body;

  String? get message => jsonDecode(body)['error']['message'];

  String get errorCode => message!.split(' ')[0];

  AuthException(this.body);

  @override
  String toString() => 'AuthException: $errorCode';
}

class SignedOutException implements Exception {
  @override
  String toString() =>
      'SignedOutException: Attempted to call a protected resource while signed out';
}

/// Allows to quickly convert any firebase exception to [ExceptionWrapper].
extension FirebaseExceptionExtension on FirebaseException {
  ExceptionWrapper toException([StackTrace? trace]) =>
      ExceptionWrapper(message ?? 'An error has occurred.',
          stackTrace: trace ?? stackTrace, code: code);
}
