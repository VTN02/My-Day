import 'package:flutter/material.dart';

/// Centralized gradients for MyDay application.
class AppGradients {
  AppGradients._();

  // Primary Brand: linear-gradient(120deg, #4338CA 0%, #7C3AED 55%, #06B6D4 100%)
  static const LinearGradient primaryBrand = LinearGradient(
    begin: Alignment(-0.86, -0.5), // ~120 degrees
    end: Alignment(0.86, 0.5),
    colors: [Color(0xFF4338CA), Color(0xFF7C3AED), Color(0xFF06B6D4)],
    stops: [0.0, 0.55, 1.0],
  );

  // Finance: linear-gradient(120deg, #0F766E, #06B6D4)
  static const LinearGradient finance = LinearGradient(
    begin: Alignment(-0.86, -0.5),
    end: Alignment(0.86, 0.5),
    colors: [Color(0xFF0F766E), Color(0xFF06B6D4)],
  );

  // Dark Hero: linear-gradient(120deg, #111827, #312E81, #6D28D9)
  static const LinearGradient darkHero = LinearGradient(
    begin: Alignment(-0.86, -0.5),
    end: Alignment(0.86, 0.5),
    colors: [Color(0xFF111827), Color(0xFF312E81), Color(0xFF6D28D9)],
  );

  // Subtle Card Gradients
  static const LinearGradient subtleCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
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
