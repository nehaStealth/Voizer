import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:agora_calling_app/src/widget/dimensions.dart';
import 'package:agora_calling_app/src/widget/style.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

InputDecoration textFieldDecoration(
    BuildContext context, {
      String? labelText,
      String? hintText,
      dynamic suffixIcon,
      dynamic prefixIcon,
      Color? fillColor,
      Color? labelColor,
      Color? borderColor,
      dynamic borderWidth,
      Color? hintColor,
      EdgeInsetsGeometry? contentPadding,
      BorderRadius? borderRadius,
      Widget? suffix,
    }) =>
    InputDecoration(
      fillColor: fillColor ?? whiteColor,
      filled: true,
      isDense: true,
      prefixIcon: prefixIcon,
      contentPadding: contentPadding ?? const EdgeInsets.only(left: 22.0, bottom: 22.0, top: 22.0, right: 22),
      border: OutlineInputBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderColor ?? HexColor(lightBlueColor), width: borderWidth ?? 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderColor ?? HexColor(lightBlueColor), width:  borderWidth ?? 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderColor ?? HexColor(lightBlueColor), width:  borderWidth ?? 1.0),
      ),
      hintText: hintText,
      hintStyle: montserratRegular.copyWith(
        color: hintColor ?? HexColor(primaryColor),
        fontSize: Dimensions.fontSizeSmall,
      ),
      labelText: labelText,
      labelStyle: montserratRegular.copyWith(
        color: labelColor ?? HexColor(primaryColor),
        fontSize: Dimensions.fontSizeSmall,
      ),
      errorStyle: montserratRegular.copyWith(
        color: HexColor(errorColor),
        fontSize: Dimensions.fontSizeSmall,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(5.0),
        borderSide: BorderSide(color: HexColor(errorColor), width: borderWidth ?? 1.0),
      ),
      suffixIcon: suffixIcon,
    );
