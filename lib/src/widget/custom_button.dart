import 'package:agora_calling_app/src/widget/style.dart';
import 'package:flutter/material.dart';

class CustomButtonWidget extends StatelessWidget {
  const CustomButtonWidget({
    Key? key,
    required this.width,
    required this.height,
    this.icon,
    this.title,
    this.iconColor,
    this.titleColor,
    this.fontSize,
    this.iconSize,
    this.border,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow = false,
    required this.onClick,
  }) : super(key: key);
  final double width;
  final double height;
  final String? title;
  final String? icon;
  final double?   fontSize;
  final double? iconSize;
  final Color? iconColor;
  final Color? titleColor;
  final BoxBorder? border;
  final Color? backgroundColor;
  final bool? boxShadow;
  final BorderRadius? borderRadius;
  final Function onClick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onClick();
      },
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: border,
          borderRadius: borderRadius,
          // boxShadow: [
          //   if (boxShadow == true)
          //     BoxShadow(
          //       color: blackColor.withOpacity(0.2),
          //       // spreadRadius: 1,
          //       blurRadius: 3,
          //       offset: const Offset(0, 3),
          //     ),
          // ],
        ),
        child: Center(
          child: title == null
              ? ImageIcon(
                  AssetImage(icon!),
                  color: iconColor,
                  size: iconSize,
                )
              : Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: montserratSemiBold.copyWith(
                    color: titleColor,
                    fontSize: fontSize,
                  ),
                ),
        ),
      ),
    );
  }
}
