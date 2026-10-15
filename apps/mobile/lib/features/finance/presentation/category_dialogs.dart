import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

/// Available icons for finance categories
const Map<String, IconData> financeCategoryIcons = {
  'restaurant': Icons.restaurant_outlined,
  'directions_car': Icons.directions_car_outlined,
  'receipt_long': Icons.receipt_long_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'movie': Icons.movie_outlined,
  'medical_services': Icons.medical_services_outlined,
  'payments': Icons.payments_outlined,
  'trending_up': Icons.trending_up_rounded,
  'school': Icons.school_outlined,
  'home': Icons.home_outlined,
  'phone_android': Icons.phone_android_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'pets': Icons.pets_outlined,
  'flight': Icons.flight_outlined,
  'card_giftcard': Icons.card_giftcard_outlined,
  'work': Icons.work_outline,
  'category': Icons.category_outlined,
};

/// Preset color palette for category customization
const List<String> financeCategoryColors = [
  '#4F46E5', // Indigo
  '#06B6D4', // Cyan
  '#10B981', // Mint
  '#F59E0B', // Amber
  '#EF4444', // Coral / Red
  '#8B5CF6', // Purple
  '#EC4899', // Pink
  '#14B8A6', // Teal
];

IconData getFinanceCategoryIcon(String? iconName) {
  if (iconName == null) return Icons.category_outlined;
  return financeCategoryIcons[iconName] ?? Icons.category_outlined;
}

Color parseCategoryColor(String? hexString, {Color fallback = AppColors.primaryIndigo}) {
  if (hexString == null || hexString.isEmpty) return fallback;
  try {
    final hex = hexString.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  } catch (_) {}
  return fallback;
}

/// Dialog to add a custom expense or income category
void showAddCategoryDialog(
  BuildContext context,
  WidgetRef ref, {
  required String type, // 'expense' or 'income'
  void Function(String newCategoryName)? onCategoryCreated,
}) {
  final nameController = TextEditingController();
  String selectedIcon = 'category';
  String selectedColor = financeCategoryColors.first;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New ${type == "expense" ? "Expense" : "Income"} Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Category Name',
                    hint: 'e.g. Gym, Subscriptions, Side Business',
                    controller: nameController,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Select Color',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: financeCategoryColors.map((colorHex) {
                      final color = parseCategoryColor(colorHex);
                      final isSel = selectedColor == colorHex;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = colorHex),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSel
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Icon',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: financeCategoryIcons.entries.map((entry) {
                      final isSel = selectedIcon == entry.key;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = entry.key),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSel
                                ? (isDark
                                    ? AppColors.darkSoftIndigo
                                    : AppColors.lightSoftIndigo)
                                : (isDark
                                    ? AppColors.darkCardSurface
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primaryIndigo
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            size: 20,
                            color: isSel
                                ? AppColors.primaryIndigo
                                : (isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Create Category',
                    isFullWidth: true,
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      await ref.read(financeRepositoryProvider).createCategory(
                            name: name,
                            type: type,
                            iconName: selectedIcon,
                            colorHex: selectedColor,
                            isCustom: true,
                          );

                      if (ctx.mounted) Navigator.of(ctx).pop();
                      onCategoryCreated?.call(name);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
