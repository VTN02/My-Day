import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/models/member_balance.dart';

/// Clean card displaying participant's outing contributions and balance.
class MemberAvatarTile extends StatelessWidget {
  final MemberBalance balance;
  final VoidCallback? onTap;

  const MemberAvatarTile({super.key, required this.balance, this.onTap});

  String _formatAmount(int minor) {
    final val = (minor.abs()) / 100.0;
    final prefix = minor > 0 ? '+Rs. ' : (minor < 0 ? '-Rs. ' : 'Rs. ');
    return '$prefix${val.toStringAsFixed(minor % 100 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color badgeColor;
    Color badgeTextColor;
    String statusText;

    if (balance.isSettled) {
      badgeColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      badgeTextColor = isDark
          ? AppColors.darkSecondaryText
          : AppColors.lightSecondaryText;
      statusText = 'Settled';
    } else if (balance.isCreditor) {
      badgeColor = isDark ? AppColors.darkSoftMint : AppColors.lightSoftMint;
      badgeTextColor = AppColors.successMint;
      statusText = 'Gets ${_formatAmount(balance.netBalanceMinor)}';
    } else {
      badgeColor = isDark ? AppColors.darkSoftCoral : AppColors.lightSoftCoral;
      badgeTextColor = AppColors.errorCoral;
      statusText = 'Owes ${_formatAmount(balance.netBalanceMinor)}';
    }

    final initial = balance.displayName.isNotEmpty
        ? balance.displayName.substring(0, 1).toUpperCase()
        : '?';

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
            CircleAvatar(
              radius: 20,
              backgroundColor: balance.isOrganizer
                  ? AppColors.primaryIndigo
                  : (isDark
                        ? AppColors.darkSoftIndigo
                        : AppColors.lightSoftIndigo),
              child: Text(
                initial,
                style: TextStyle(
                  color: balance.isOrganizer
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.primaryIndigo),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        balance.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      if (balance.isOrganizer) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryIndigo.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Organizer',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryIndigo,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paid: Rs. ${(balance.totalPaidMinor / 100).toStringAsFixed(0)} • Share: Rs. ${(balance.totalShareMinor / 100).toStringAsFixed(0)}',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: badgeTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
