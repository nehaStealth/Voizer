import 'package:agora_calling_app/src/helpers/texts.dart';

class FormValidator {
  static FormValidator? _instance;

  factory FormValidator() => _instance ??= FormValidator._();

  FormValidator._();

  String? validateName(String value) {
    if (value.isEmpty) {
      return validateNameTxt;
    }
    return null;
  }

  String? validatePassword(String value) {
    if (value.isEmpty) {
      return validatePassTxt;
    }
    return null;
  }
  String? validateNewPassword(String value) {
    if (value.isEmpty) {
      return validateNewPasswordTxt;
    }
    return null;
  }

  String? validateConfirmPassword(String value, password) {
    if(value.isEmpty) {
      return validateCPassTxt;
    }
    if(value != password) {
      return validateConfirmPasswordTxt;
    }
    return null;
  }

}