import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/group_expenses_providers.dart';

/// Screen: Outing Settings (Status management, editing, and deletion safeguards).
class OutingSettingsScreen extends ConsumerWidget {
  final String outingId;

  const OutingSettingsScreen({super.key, required this.outingId});

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String newStatus,
  ) async {
    await ref
        .read(groupExpensesRepositoryProvider)
        .updateOutingStatus(outingId, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Outing marked as ${newStatus.toUpperCase()}')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Outing?'),
        content: const Text(
          'Are you sure you want to delete this outing? All expense records and participant balances will be archived and removed from your dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorCoral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Outing'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(groupExpensesRepositoryProvider).deleteOuting(outingId);
      if (context.mounted) {
        context.go('/split');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outingAsync = ref.watch(outingDetailStreamProvider(outingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Outing Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: outingAsync.when(
        data: (outing) {
          if (outing == null) {
            return const Center(child: Text('Outing not found.'));
          }

          final currentStatus = outing.status;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Outing Status Section
              Text(
                'Outing Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Switch status as your outing progresses from planning to completion.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 12),

              _StatusRadioTile(
                title: 'Active',
                subtitle: 'Currently happening or ongoing expenses',
                value: 'active',
                groupValue: currentStatus,
                onChanged: (val) => _updateStatus(context, ref, val!),
              ),
              _StatusRadioTile(
                title: 'Completed',
                subtitle: 'Trip finished and all expenses recorded',
                value: 'completed',
                groupValue: currentStatus,
                onChanged: (val) => _updateStatus(context, ref, val!),
              ),
              _StatusRadioTile(
                title: 'Planned',
                subtitle: 'Upcoming trip in preparation',
                value: 'planned',
                groupValue: currentStatus,
                onChanged: (val) => _updateStatus(context, ref, val!),
              ),
              _StatusRadioTile(
                title: 'Archived',
                subtitle: 'Hidden from active views, preserved for records',
                value: 'archived',
                groupValue: currentStatus,
                onChanged: (val) => _updateStatus(context, ref, val!),
              ),
              const SizedBox(height: 24),

              // Actions
              Text(
                'Outing Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 12),

              ListTile(
                onTap: () => context.push('/split/$outingId/edit'),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardRadius,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                tileColor: isDark
                    ? AppColors.darkCardSurface
                    : AppColors.lightCardSurface,
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primaryIndigo,
                ),
                title: const Text(
                  'Edit Outing Details',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Change name, budget, date, or notes'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              ),
              const SizedBox(height: 12),

              ListTile(
                onTap: () => _confirmDelete(context, ref),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardRadius,
                  side: BorderSide(
                    color: AppColors.errorCoral.withValues(alpha: 0.3),
                  ),
                ),
                tileColor: isDark
                    ? AppColors.darkCardSurface
                    : AppColors.lightCardSurface,
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.errorCoral,
                ),
                title: const Text(
                  'Delete Outing',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorCoral,
                  ),
                ),
                subtitle: const Text('Safely delete and remove this outing'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _StatusRadioTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _StatusRadioTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: AppRadius.cardRadius,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardSurface
              : AppColors.lightCardSurface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryIndigo
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? AppColors.primaryIndigo
                  : (isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
          ],
        ),
      ),
    );
  }
}
