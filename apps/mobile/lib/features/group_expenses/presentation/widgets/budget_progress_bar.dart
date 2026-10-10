import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Clean budget progress bar widget for outing budgets.
class BudgetProgressBar extends StatelessWidget {
  final int spentMinor;
  final int budgetMinor;
  final String currency;

  const BudgetProgressBar({
    super.key,
    required this.spentMinor,
    required this.budgetMinor,
    this.currency = 'LKR',
  });

  String _formatAmount(int minor) {
    final val = minor / 100.0;
    return 'Rs. ${val.toStringAsFixed(minor % 100 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = budgetMinor > 0 ? (spentMinor / budgetMinor) : 0.0;
    final percent = (ratio * 100).round();
    final remainingMinor = budgetMinor - spentMinor;
    final isOverBudget = remainingMinor < 0;

    final progressColor = isOverBudget
        ? AppColors.errorCoral
        : (ratio > 0.85 ? AppColors.warningAmber : AppColors.successMint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Usage',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: Container(
            height: 8,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.lightBorder,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio.clamp(0.0, 1.0),
              child: Container(color: progressColor),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: ${_formatAmount(spentMinor)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              isOverBudget
                  ? 'Over by: ${_formatAmount(-remainingMinor)}'
                  : 'Remaining: ${_formatAmount(remainingMinor)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOverBudget
                    ? AppColors.errorCoral
                    : AppColors.successMint,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
