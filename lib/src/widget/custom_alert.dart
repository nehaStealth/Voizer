import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:agora_calling_app/src/widget/dimensions.dart';
import 'package:agora_calling_app/src/widget/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

void showContentAlert({
  required BuildContext context,
  Widget? child,
  double? width,
  double? height,
}) {
  showGeneralDialog(
    barrierColor: blackColor.withOpacity(0.5),
    transitionBuilder: (context, animation, secondaryAnimation, widget) {
      return Transform.scale(
        scale: animation.value,
        child: Opacity(
          opacity: animation.value,
          child: AlertDialog(
            contentPadding: const EdgeInsets.all(20.0),
            insetPadding: const EdgeInsets.only(left: 30.0, right: 30.0),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            actionsPadding: EdgeInsets.zero,
            content: (child != null)
                ? SizedBox(
                    height: height,
                    child: child,
                  )
                : Container(),
            actionsAlignment: MainAxisAlignment.center,
            buttonPadding: EdgeInsets.zero,
            alignment: Alignment.center,
            titleTextStyle: montserratBold.copyWith(color: blackColor, fontSize: Dimensions.fontSizeOverLarge),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
    barrierDismissible: false,
    barrierLabel: '',
    context: context,
    pageBuilder: (context, animation1, animation2) => Container(),
  );
}

void showBGContentAlert({
  required BuildContext context,
  Widget? child,
  double? width,
  double? height,
}) {
  showGeneralDialog(
    barrierColor: blackColor.withOpacity(0.5),
    transitionBuilder: (context, animation, secondaryAnimation, widget) {
      return Transform.scale(
        scale: animation.value,
        child: Opacity(
          opacity: animation.value,
          child: AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            backgroundColor: HexColor(darkBlueColor),
            // shape: const RoundedRectangleBorder(
            //   borderRadius: BorderRadius.all(Radius.circular(20.0)),
            // ),
            actionsPadding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage('assets/images/bg-2.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: (child != null)
                  ? SizedBox(
                      height: height,
                      child: child,
                    )
                  : Container(),
            ),
            actionsAlignment: MainAxisAlignment.center,
            buttonPadding: EdgeInsets.zero,
            alignment: Alignment.center,
            titleTextStyle: montserratBold.copyWith(color: blackColor, fontSize: Dimensions.fontSizeOverLarge),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
    barrierDismissible: false,
    barrierLabel: '',
    context: context,
    pageBuilder: (context, animation1, animation2) => Container(),
  );
}

void showLoadingAlert({required BuildContext context, String message = "Loading..."}) {
  showGeneralDialog(
    barrierColor: blackColor.withOpacity(0.5),
    transitionBuilder: (context, animation, secondaryAnimation, widget) {
      return Transform.scale(
        scale: animation.value,
        child: Opacity(
          opacity: animation.value,
          child: WillPopScope(
            onWillPop: () async => true,
            child: AlertDialog(
              shape: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: [
                      SizedBox( width:30,height: 30,child: CircularProgressIndicator()),
                      SizedBox(width: 30),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: montserratMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: blackColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
    barrierDismissible: false,
    barrierLabel: '',
    context: context,
    pageBuilder: (context, animation1, animation2) => Container(),
  );
}

void showMessageAlert({required BuildContext context, String message = "Something went wrong", required Function() onClick, bool isDismissable = true}) {
  showGeneralDialog(
    context: context,
    pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      return PopScope(
        canPop: isDismissable,
        child: CupertinoAlertDialog(
          title: Text(
            message,
            style: montserratMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: blackColor,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: onClick,
              child: Text(
                "OK",
                style: montserratMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: HexColor(mediumLightColor),
                ),
              ),
            ),
          ],
        ),
      );
    },
    barrierDismissible: isDismissable,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 200),
  );
}