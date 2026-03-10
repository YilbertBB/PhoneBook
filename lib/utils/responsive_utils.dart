import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Método para detectar el tipo de pantalla
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return ScreenType.mobile;
    } else if (width < 900) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  // Método para obtener tamaño responsive
  static double getResponsiveValue({
    required BuildContext context,
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile * 1.2;
      case ScreenType.desktop:
        return desktop ?? mobile * 1.5;
    }
  }

  // Método para obtener padding responsive
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return EdgeInsets.all(16);
      case ScreenType.tablet:
        return EdgeInsets.all(24);
      case ScreenType.desktop:
        return EdgeInsets.all(32);
    }
  }

  // Método para obtener tamaño de texto responsive
  static double getResponsiveTextSize(BuildContext context, double baseSize) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseSize;
      case ScreenType.tablet:
        return baseSize * 1.1;
      case ScreenType.desktop:
        return baseSize * 1.2;
    }
  }

  // Método para grid responsive
  static int getResponsiveGridCount(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 2;
      case ScreenType.tablet:
        return 3;
      case ScreenType.desktop:
        return 4;
    }
  }
}

enum ScreenType { mobile, tablet, desktop }
