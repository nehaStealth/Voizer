import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:agora_calling_app/src/widget/dimensions.dart';
import 'package:agora_calling_app/src/widget/style.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    Key? key,
    required this.textType,
    this.focusNode,
    this.controller,
    required this.obscureText,
    required this.decoration,
    this.style,
    this.maxLines,
    this.minLines,
    this.textAlign,
    this.onChanged,
    this.onFieldSubmitted,
    this.onSaved,
    this.validator,
    this.isEnabled,
    this.onTapValue,
  }) : super(key: key);

  final TextInputType textType;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final bool obscureText;
  final InputDecoration decoration;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final TextAlign? textAlign;
  final void Function(String)? onChanged;
  final Function? onFieldSubmitted;
  final Function(String? items)? onSaved;
  final FormFieldValidator<String>? validator;
  final bool? isEnabled;
  final Function? onTapValue;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: isEnabled,
      cursorColor: blackColor,
      focusNode: focusNode,
      keyboardType: textType,
      controller: controller,
      obscureText: obscureText,
      decoration: decoration,
      textAlign: textAlign ?? TextAlign.start,
      style: style ?? montserratMedium.copyWith(
        color: HexColor(primaryColor),
        fontSize: Dimensions.fontSizeSmall,
      ),
      maxLines: maxLines,
      minLines: minLines,
      validator: validator,
      onSaved: (value) {
        onSaved!(value);
      },
      onFieldSubmitted: (String value) {
        onFieldSubmitted!(value);
      },
      onTap: () {
        onTapValue!();
      },
      onChanged: (value) {
        return onChanged != null ? onChanged!(value) : value;
      },
    );
  }
}
