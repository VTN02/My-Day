import 'package:flutter/material.dart';

/// Centralized gradients for MyDay application.
class AppGradients {
  AppGradients._();

  // Primary Brand Ocean Blue: linear-gradient(120deg, #1565C0 0%, #0288D1 55%, #4DD0E1 100%)
  static const LinearGradient primaryBrand = LinearGradient(
    begin: Alignment(-0.86, -0.5), // ~120 degrees
    end: Alignment(0.86, 0.5),
    colors: [Color(0xFF1565C0), Color(0xFF0288D1), Color(0xFF4DD0E1)],
    stops: [0.0, 0.55, 1.0],
  );

  // Finance: linear-gradient(120deg, #0288D1, #4DD0E1)
  static const LinearGradient finance = LinearGradient(
    begin: Alignment(-0.86, -0.5),
    end: Alignment(0.86, 0.5),
    colors: [Color(0xFF0288D1), Color(0xFF4DD0E1)],
  );

  // Dark Hero: linear-gradient(120deg, #0D1B2A, #1B263B, #0288D1)
  static const LinearGradient darkHero = LinearGradient(
    begin: Alignment(-0.86, -0.5),
    end: Alignment(0.86, 0.5),
    colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF0288D1)],
  );

  // Subtle Card Gradients
  static const LinearGradient subtleCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
  );

  // Mint / Success Gradient
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
  );

  // Coral / Expense Gradient
  static const LinearGradient coral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97373), Color(0xFFFB7185)],
  );
}
