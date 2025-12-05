class   Dimensions {
  static const double fontSizeExtraSmallButton = 8.0;
  static const double fontSizeExtraSmallBtn = 9.0;
  static const double fontSizeExtraSmall = 10.0;
  static const double fontSizeVeryExtraSmall = 11.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRate = 13.0;

  static const double fontSizeDefault = 14.0;
  static const double fontSizeExtraDefault = 15.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeExtraLarge = 18.0;
  static const double fontSizeVeryExtraLarge = 20.0;
  static const double fontSizeExtraLargeBanner = 22.0;
  static const double fontSizeOverLarge = 24.0;
  static const double fontSizeVeryExtraOverLarge = 28.0;
  static const double fontSizeExtraMediumOverLarge = 30.0;
  static const double fontSizeExtraOverLarge = 32.0;
  static const double fontSizeVeryOverLarge = 36.0;
}
extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ?'${this[0].toUpperCase()}${substring(1).toLowerCase()}':'';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}
