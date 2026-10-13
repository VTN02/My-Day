import 'package:flutter/material.dart';

/// Centralized brand color palette for MyDay.
class AppColors {
  AppColors._();

  // Core Brand Colors - Ocean Blue Theme
  static const Color primaryOcean = Color(0xFF1565C0);
  static const Color secondaryOcean = Color(0xFF0288D1);
  static const Color accentCyan = Color(0xFF4DD0E1);
  static const Color successMint = Color(0xFF10B981);
  static const Color errorCoral = Color(0xFFF97373);

  // Backward-compatibility aliases
  static const Color primaryIndigo = primaryOcean;
  static const Color secondaryViolet = secondaryOcean;

  // Light Theme Surfaces & Text
  static const Color lightBackground = Color(0xFFF5F9FC);
  static const Color lightCardSurface = Color(0xFFFFFFFF);
  static const Color lightPrimaryText = Color(0xFF172B4D);
  static const Color lightSecondaryText = Color(0xFF5E6C84);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightSoftIndigo = Color(0xFFE3F2FD);
  static const Color lightSoftOcean = Color(0xFFE3F2FD);
  static const Color lightSoftMint = Color(0xFFECFDF5);
  static const Color lightSoftCoral = Color(0xFFFFF1F2);

  // Dark Theme Surfaces & Text
  static const Color darkBackground = Color(0xFF0D1B2A);
  static const Color darkCardSurface = Color(0xFF1B263B);
  static const Color darkPrimaryText = Color(0xFFF1F5F9);
  static const Color darkSecondaryText = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF24344D);
  static const Color darkSoftIndigo = Color(0xFF16325B);
  static const Color darkSoftOcean = Color(0xFF16325B);
  static const Color darkSoftMint = Color(0xFF064E3B);
  static const Color darkSoftCoral = Color(0xFF4C0519);

  // Priority & Warning Colors
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color lightSoftAmber = Color(0xFFFFFBEB);
  static const Color darkSoftAmber = Color(0xFF451A03);
}
