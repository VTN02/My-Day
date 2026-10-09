import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Navigation item definition.
class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// Modern Edge-to-Edge Bottom Navigation Dock matching flagship mobile OS patterns.
class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final bgColor = isDark
        ? const Color(0xF2121829)
        : const Color(0xF8FFFFFF);

    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.8)
        : AppColors.lightBorder.withValues(alpha: 0.9);

    final unselectedColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(color: borderColor, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: bottomInset > 0 ? bottomInset : 8,
          top: 6,
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(index);
                    },
                    splashColor: AppColors.primaryIndigo.withValues(alpha: 0.1),
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.primaryIndigo.withValues(alpha: 0.22)
                                    : AppColors.primaryIndigo.withValues(alpha: 0.12))
                                : Colors.transparent,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 22,
                            color: isSelected
                                ? AppColors.primaryIndigo
                                : unselectedColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: -0.1,
                            color: isSelected
                                ? AppColors.primaryIndigo
                                : unselectedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
