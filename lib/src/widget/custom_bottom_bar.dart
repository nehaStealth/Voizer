import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

class CustomBottomBar extends StatefulWidget {
  final Color? bgColor;

  const CustomBottomBar({Key? key, this.bgColor}) : super(key: key);

  @override
  State createState() => _CustomBigBottomBarState();
}

class _CustomBigBottomBarState extends State<CustomBottomBar> {
  @override
  void initState() {
    super.initState();
    // _selectedIndex = widget.selectedIndex!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: widget.bgColor ?? HexColor(mediumLightColor),
      width: MediaQuery.sizeOf(context).width,
    );
  }
}
