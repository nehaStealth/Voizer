import 'package:flutter/material.dart';

class CustomListViewWidget extends StatelessWidget {
  const CustomListViewWidget({
    Key? key,
    this.padding,
    this.direction,
    required this.itemCount,
    required this.itemBuilder,
  }) : super(key: key);
  final EdgeInsetsGeometry? padding;
  final dynamic direction;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ListView.builder(
      padding: padding,
      primary: false,
      shrinkWrap: true,
      scrollDirection: direction,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
