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

  bool get isTablet => screenWidth >= AppConstants.breakpointTablet;
  bool get isDesktop => screenWidth >= AppConstants.breakpointDesktop;

  T adaptiveValue<T>({
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  double get maxContentWidth => adaptiveValue(
        mobile: double.infinity,
        tablet: AppConstants.maxContentWidthTablet,
        desktop: AppConstants.maxContentWidthDesktop,
      );

  double get maxSheetHeight => adaptiveValue(
        mobile: screenHeight,
        tablet: (screenHeight * 0.85).clamp(0.0, 700.0),
        desktop: 740.0,
      );

  double get maxAuthWidth => adaptiveValue(
        mobile: double.infinity,
        tablet: AppConstants.maxAuthWidthTablet,
        desktop: AppConstants.maxAuthWidthDesktop,
      );
}
