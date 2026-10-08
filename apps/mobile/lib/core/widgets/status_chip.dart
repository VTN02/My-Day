import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Reusable status chip or category filter badge.
class StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int? count;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? activeColor;

  const StatusChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.count,
    this.icon,
    this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = activeColor ?? AppColors.primaryIndigo;

    final bgColor = isSelected
        ? (isDark ? AppColors.darkSoftIndigo : AppColors.lightSoftIndigo)
        : (isDark ? AppColors.darkCardSurface : const Color(0xFFEFF2FA));

    final textColor = isSelected
        ? primaryColor
        : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText);

    final borderColor = isSelected
        ? primaryColor.withValues(alpha: 0.4)
        : (isDark ? AppColors.darkBorder : Colors.transparent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.chipRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.chipRadius,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: textColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? AppColors.darkBorder : Colors.black12),
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
