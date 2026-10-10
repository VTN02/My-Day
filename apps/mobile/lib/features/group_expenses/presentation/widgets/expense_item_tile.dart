import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/models/expense_with_shares.dart';

/// Card displaying an outing expense with category icon, payer, and amount.
class ExpenseItemTile extends StatelessWidget {
  final ExpenseWithShares item;
  final VoidCallback onTap;

  const ExpenseItemTile({super.key, required this.item, required this.onTap});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'tickets':
      case 'entertainment':
        return Icons.confirmation_number_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'accommodation':
        return Icons.hotel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFF59E0B); // Amber
      case 'transport':
        return AppColors.accentCyan;
      case 'tickets':
      case 'entertainment':
        return AppColors.secondaryViolet;
      case 'shopping':
        return const Color(0xFFEC4899); // Pink
      case 'accommodation':
        return AppColors.primaryIndigo;
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  String _formatAmount(int minor) {
    final val = minor / 100.0;
    return 'Rs. ${val.toStringAsFixed(minor % 100 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _getCategoryColor(item.expense.category);
    final count = item.participantCount;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardSurface
              : AppColors.lightCardSurface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(item.expense.category),
                color: catColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.expense.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Paid by ${item.payer.displayName} • $count friends',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(item.expense.amountMinor),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${(item.expense.amountMinor / (count > 0 ? count : 1) / 100).toStringAsFixed(0)} / person',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
