import 'package:flutter/material.dart';

/// Global design tokens for colors, spacing, typography, depth, and layout.
/// These tokens centralise styling rules so all screens stay in sync across
/// responsive breakpoints.
class DSBreakpoints {
  DSBreakpoints._();

  static const double xs = 0;
  static const double sm = 480;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1440;
}

class DSSpacing {
  DSSpacing._();

  static const double x2s = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double x2l = 48;
  static const double x3l = 64;
}

class DSRadii {
  DSRadii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

class DSShadows {
  DSShadows._();

  static const BoxShadow sm = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 12,
    offset: Offset(0, 6),
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x3D000000),
    blurRadius: 48,
    offset: Offset(0, 24),
  );
}

class DSTextStyles {
  DSTextStyles._();

  static const String fontFamily = 'Inter';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static const TextStyle titleLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle titleSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.02,
  );
}
