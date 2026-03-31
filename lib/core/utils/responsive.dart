import 'package:flutter/material.dart';
import 'package:mapy/core/constants/app_constants.dart';

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get screenPadding => MediaQuery.paddingOf(this);
  double get topPadding => screenPadding.top;
  double get bottomPadding => screenPadding.bottom;

  double w(double designWidth) =>
      screenWidth * (designWidth / AppConstants.designWidth);
  double h(double designHeight) =>
      screenHeight * (designHeight / AppConstants.designHeight);
  double sp(double designFontSize) {
    final scale = screenWidth / AppConstants.designWidth;
    return designFontSize * scale.clamp(0.8, 1.3);
  }

  double get scaleFactor {
    final s = screenWidth / AppConstants.designWidth;
    return s.clamp(0.75, 1.4);
  }

  double r(double radius) => radius * scaleFactor;
}
