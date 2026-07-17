import 'package:flutter/material.dart';

import '../../menstrual_cycle_widget_base.dart';

/// Returns an explicitly configured font family, when there is one.
///
/// `Default` is the package's historical placeholder rather than a bundled
/// font. Passing it to a [TextStyle] works inconsistently on the web and can
/// leave Arabic glyphs without a usable fallback. Returning `null` lets
/// Flutter select its platform Arabic fallback and keep the letters joined.
String? getFontFamily() {
  final family = MenstrualCycleWidget.instance?.getDefaultFontFamily().trim();
  if (family == null || family.isEmpty || family.toLowerCase() == 'default') {
    return null;
  }
  return family;
}

/// text style with black color and font size is 10
TextStyle textStyleBlack10() {
  return TextStyle(
      color: Colors.black, fontSize: 10, fontFamily: getFontFamily());
}

/// get text style
TextStyle getTextStyle(TextStyle? style) => style ?? textStyleBlack10();

/// get text style with font size 24 and bold
TextStyle textStyle24Bold() {
  return TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: getFontFamily(),
  );
}
