import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Reusable Note card component.
class NoteCard extends StatelessWidget {
  final String title;
  final String body;
  final String category;
  final String date;
  final String? attachmentName;
  final bool isPinned;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onPinToggle;

  const NoteCard({
    super.key,
    required this.title,
    required this.body,
    required this.category,
    required this.date,
    this.attachmentName,
    this.isPinned = false,
    this.onTap,
    this.onDelete,
    this.onPinToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final borderColor = isPinned
        ? AppColors.primaryIndigo.withAlpha(120)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: borderColor,
          width: isPinned ? 1.5 : 1.0,
        ),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isPinned) ...[
                      const Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: AppColors.primaryIndigo,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onPinToggle != null)
                          GestureDetector(
                            onTap: onPinToggle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(
                                isPinned
                                    ? Icons.push_pin_rounded
                                    : Icons.push_pin_outlined,
                                size: 18,
                                color: isPinned
                                    ? AppColors.primaryIndigo
                                    : (isDark
                                          ? AppColors.darkSecondaryText
                                          : AppColors.lightSecondaryText),
                              ),
                            ),
                          ),
                        if (onDelete != null)
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSoftIndigo
                                : AppColors.lightSoftIndigo,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryIndigo,
                            ),
                          ),
                        ),
                        if (attachmentName != null) ...[
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_file,
                                size: 13,
                                color: AppColors.accentCyan,
                              ),
                              const SizedBox(width: 2),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 100,
                                ),
                                child: Text(
                                  attachmentName!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.accentCyan,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Text(
                      date,
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
        ),
      ),
    );
  }
}
