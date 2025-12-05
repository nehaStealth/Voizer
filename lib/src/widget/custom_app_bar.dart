import 'package:agora_calling_app/src/helpers/texts.dart';
import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:agora_calling_app/src/widget/custom_alert.dart';
import 'package:agora_calling_app/src/widget/custom_button.dart';
import 'package:agora_calling_app/src/widget/dimensions.dart';
import 'package:agora_calling_app/src/widget/style.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

// ignore: non_constant_identifier_names
CustomSmallAppBar(
    BuildContext context, {
      required String? title,
      bool? leading = false,
      bool? centerTitle = false,
      Color? bgColor,
      Color? iconColor,
      Color? titleColor,
      Function? onBack,
      bool? actions = false,
      int notificationCount = 0, // 👈 add this
      bool? showNotification = false,
      Function? onNotificationTap,
    }) {
  return Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.only(top: 25.0, left: 8.0, right: 10.0),
    width: MediaQuery.of(context).size.width,
    height: 90.0,
    decoration: BoxDecoration(
      color: bgColor ?? HexColor(mediumLightColor),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (leading! == true) ...[
          Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(41.0),
            ),
            clipBehavior: Clip.hardEdge,
            color: Colors.transparent,
            child: Ink(
              width: 41.0,
              height: 41.0,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(41.0),
              ),
              child: InkWell(
                onTap: () {
                  onBack!();
                },
                child: Center(
                  child: ImageIcon(
                    const AssetImage('assets/icons/backArrow.png'),
                    color: iconColor ?? whiteColor,
                    size: Dimensions.fontSizeVeryExtraOverLarge,
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(0.0),
              width: 15.0,
              height: 41.0,
            ),
          )
        ],
        Text(
          title!,
          style: montserratExtraBold.copyWith(
            color: titleColor ?? whiteColor,
            fontSize: Dimensions.fontSizeVeryExtraLarge,
          ),
        ),
        if (actions! == true) ...[
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Notification Icon with count
                if (showNotification!) Stack(
                  children: [
                    Material(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(41.0),
                      ),
                      clipBehavior: Clip.hardEdge,
                      color: Colors.transparent,
                      child: Ink(
                        width: 41.0,
                        height: 41.0,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(41.0),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (onNotificationTap != null) {
                              onNotificationTap!();
                            }
                          },
                          child: Center(
                            child: ImageIcon(
                              const AssetImage('assets/icons/bell.png'),
                              color: iconColor ?? whiteColor,
                              size: Dimensions.fontSizeVeryExtraOverLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 🔴 Notification Count Badge
                    if (notificationCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16.0),

                // Logout icon
                // Material(
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(41.0),
                //   ),
                //   clipBehavior: Clip.hardEdge,
                //   color: Colors.transparent,
                //   child: Ink(
                //     width: 41.0,
                //     height: 41.0,
                //     decoration: BoxDecoration(
                //       color: Colors.transparent,
                //       border: Border.all(color: Colors.transparent),
                //       borderRadius: BorderRadius.circular(41.0),
                //     ),
                //     child: InkWell(
                //       onTap: () {
                //         onBack!();
                //       },
                //       child: Center(
                //         child: ImageIcon(
                //           const AssetImage('assets/icons/logout.png'),
                //           color: iconColor ?? whiteColor,
                //           size: Dimensions.fontSizeVeryExtraOverLarge,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),


          // Center(
          //   child: Material(
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(41.0),
          //     ),
          //     clipBehavior: Clip.hardEdge,
          //     color: Colors.transparent,
          //     child: Ink(
          //       width: 41.0,
          //       height: 41.0,
          //       decoration: BoxDecoration(
          //         color: Colors.transparent,
          //         border: Border.all(color: Colors.transparent),
          //         borderRadius: BorderRadius.circular(41.0),
          //       ),
          //       child: InkWell(
          //         onTap: () {
          //           onBack!();
          //         },
          //         child:  Center(
          //           child: ImageIcon(
          //             AssetImage('assets/icons/logout.png'),
          //             color: iconColor ?? whiteColor,
          //             size: Dimensions.fontSizeVeryExtraOverLarge,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ]else ...[
          Container(
            padding: const EdgeInsets.all(0.0),
            width: 41.0,
            height: 41.0,
          ),
        ],


      ],
    ),
  );
}
