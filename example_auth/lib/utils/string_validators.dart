library string_validators;

import 'package:flutter/services.dart';

final TextInputFormatter emailInputFormatter =
    ValidatorInputFormatter(editingValidator: EmailEditingRegexValidator());

final StringValidator _emailValidator = EmailSubmitRegexValidator();

final StringValidator _passwordRegisterValidator = MinLengthStringValidator(6);

bool emailIsValid(String? text) =>
    text != null && text.isNotEmpty && _emailValidator.isValid(text);

bool passwordIsValid(String? text) =>
    text != null && text.isNotEmpty && _passwordRegisterValidator.isValid(text);

abstract class StringValidator {
  bool isValid(String value);
}

class RegexValidator implements StringValidator {
  final String regexSource;
  final bool caseSensitive;
  final bool dotAll;

  RegexValidator(
      {required this.regexSource,
      this.caseSensitive = true,
      this.dotAll = false});

  @override
  bool isValid(String value) {
    try {
      // https://regex101.com/
      final RegExp regex =
          RegExp(regexSource, caseSensitive: caseSensitive, dotAll: dotAll);
      final Iterable<Match> matches = regex.allMatches(value);
      for (final match in matches) {
        if (match.start == 0 && match.end == value.length) {
          return true;
        }
      }
      return false;
    } catch (e) {
      // Invalid regex
      assert(false, e.toString());
      return true;
    }
  }
}

class ValidatorInputFormatter implements TextInputFormatter {
  ValidatorInputFormatter({required this.editingValidator});

  final StringValidator editingValidator;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final bool oldValueValid = editingValidator.isValid(oldValue.text);
    final bool newValueValid = editingValidator.isValid(newValue.text);
    if (oldValueValid && !newValueValid) {
      return oldValue;
    }
    return newValue;
  }
}

class EmailEditingRegexValidator extends RegexValidator {
  EmailEditingRegexValidator() : super(regexSource: '^(|\\S)+\$');
}

class EmailSubmitRegexValidator extends RegexValidator {
  EmailSubmitRegexValidator()
      : super(
          regexSource: r'([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4})',
          caseSensitive: false,
          dotAll: true,
        );
}

class MinLengthStringValidator extends StringValidator {
  MinLengthStringValidator(this.minLength);

  final int minLength;

  @override
  bool isValid(String value) {
    return value.length >= minLength;
  }
}

/// This is a callable form field validator class than can be passed as
/// a validator function in form fields of type: String.
class NotEmptyValidator {
  /// Message to be shown when validation fails. This allows this to be more
  /// flexible on usage.
  final String message;

  const NotEmptyValidator({this.message = 'Please enter a value.'});

  String? call(String? value) {
    if (value?.isEmpty ?? true) {
      return message;
    }
    return null;
  }
}
