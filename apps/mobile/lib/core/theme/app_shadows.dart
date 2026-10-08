import 'package:flutter/material.dart';

/// Centralized shadows for refined elevation.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> cardLight = [
    BoxShadow(color: Color(0x0C17243B), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> cardDark = [
    BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x334F46E5), blurRadius: 20, offset: Offset(0, 8)),
  ];
}
