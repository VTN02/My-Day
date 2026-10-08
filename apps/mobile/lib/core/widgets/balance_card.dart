import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Account / Balance card for Finance tracking (Cash & Card).
class BalanceCard extends StatelessWidget {
  final String title;
  final String amount;
  final String? subtitle;
  final IconData icon;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const BalanceCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    this.subtitle,
    this.gradient,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final defaultBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isGradient = gradient != null;

    final primaryTextCol = isGradient
        ? Colors.white
        : (textColor ??
              (isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText));
    final secondaryTextCol = isGradient
        ? Colors.white.withValues(alpha: 0.8)
        : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText);

    return Container(
      decoration: BoxDecoration(
        color: isGradient ? null : (backgroundColor ?? defaultBg),
        gradient: gradient,
        borderRadius: AppRadius.cardRadius,
        border: isGradient ? null : Border.all(color: defaultBorder),
        boxShadow: isGradient
            ? AppShadows.floating
            : (isDark ? AppShadows.cardDark : AppShadows.cardLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextCol,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isGradient
                            ? Colors.white.withValues(alpha: 0.2)
                            : (isDark
                                  ? AppColors.darkSoftIndigo
                                  : AppColors.lightSoftIndigo),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isGradient
                            ? Colors.white
                            : AppColors.primaryIndigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: primaryTextCol,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextCol,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
