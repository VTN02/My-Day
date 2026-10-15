import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../domain/models/budget_progress.dart';

/// Interactive Budgets Tab supporting Daily, Weekly, and Monthly spending budgets
/// with threshold alert badges, pause/resume, and real-time Drift calculation.
class BudgetsTab extends ConsumerStatefulWidget {
  final List<FinancialTransactionEntry> allTransactions;
  final bool isDark;

  const BudgetsTab({
    super.key,
    required this.allTransactions,
    required this.isDark,
  });

  @override
  ConsumerState<BudgetsTab> createState() => _BudgetsTabState();
}

class _BudgetsTabState extends ConsumerState<BudgetsTab> {
  String _selectedFilter = 'All'; // 'All', 'Daily', 'Weekly', 'Monthly'

  String _formatCents(int cents) {
    final val = cents / 100.0;
    return 'Rs. ${val.toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
  }

  void _showBudgetDialog({BudgetEntry? existingBudget}) {
    final nameController = TextEditingController(text: existingBudget?.name ?? '');
    final amountController = TextEditingController(
      text: existingBudget != null
          ? (existingBudget.amountCents / 100.0).toStringAsFixed(0)
          : '',
    );
    String periodType = existingBudget?.periodType ?? 'monthly';
    String? selectedCategory = existingBudget?.category ?? 'All';
    double threshold = (existingBudget?.alertThresholdPercent ?? 80).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final categoriesAsync = ref.watch(expenseCategoriesStreamProvider);

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
                          existingBudget != null ? 'Edit Budget' : 'Create New Budget',
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
                      label: 'Budget Name',
                      hint: 'e.g. Daily Food, Weekly Transport, Monthly Target',
                      controller: nameController,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Amount (LKR)',
                      hint: 'e.g. 15000',
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      controller: amountController,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Period Type',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['daily', 'weekly', 'monthly'].map((p) {
                        final isSel = periodType.toLowerCase() == p;
                        final label = p[0].toUpperCase() + p.substring(1);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: OutlinedButton(
                              onPressed: () => setModalState(() => periodType = p),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isSel
                                    ? (isDark
                                        ? AppColors.darkSoftIndigo
                                        : AppColors.lightSoftIndigo)
                                    : Colors.transparent,
                                side: BorderSide(
                                  color: isSel
                                      ? AppColors.primaryIndigo
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel
                                      ? AppColors.primaryIndigo
                                      : (isDark
                                          ? AppColors.darkPrimaryText
                                          : AppColors.lightPrimaryText),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category Filter (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    categoriesAsync.when(
                      loading: () => const SizedBox(
                        height: 36,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (err, stack) => const SizedBox.shrink(),
                      data: (cats) {
                        final catNames = ['All', ...cats.map((c) => c.name)];
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: catNames.map((c) {
                              final isSel = selectedCategory == c;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(c),
                                  selected: isSel,
                                  selectedColor: AppColors.primaryIndigo,
                                  backgroundColor: isDark
                                      ? AppColors.darkCardSurface
                                      : const Color(0xFFEFF2FA),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    color: isSel
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkPrimaryText
                                            : AppColors.lightPrimaryText),
                                  ),
                                  onSelected: (_) =>
                                      setModalState(() => selectedCategory = c),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Alert Threshold',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        Text(
                          '${threshold.toInt()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warningAmber,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: threshold,
                      min: 50,
                      max: 100,
                      divisions: 10,
                      activeColor: AppColors.warningAmber,
                      inactiveColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      onChanged: (val) => setModalState(() => threshold = val),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: existingBudget != null ? 'Update Budget' : 'Save Budget',
                      isFullWidth: true,
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final raw = double.tryParse(amountController.text.trim()) ?? 0;
                        if (name.isEmpty || raw <= 0) return;

                        final amountCents = (raw * 100).round();
                        final catVal = selectedCategory == 'All' ? null : selectedCategory;

                        if (existingBudget != null) {
                          final updated = existingBudget.copyWith(
                            name: name,
                            amountCents: amountCents,
                            periodType: periodType,
                            category: Value(catVal),
                            alertThresholdPercent: threshold.toInt(),
                          );
                          await ref
                              .read(financeRepositoryProvider)
                              .updateBudget(updated);
                        } else {
                          await ref.read(financeRepositoryProvider).createBudget(
                                name: name,
                                amountCents: amountCents,
                                periodType: periodType,
                                startDate: DateTime.now(),
                                category: catVal,
                                alertThresholdPercent: threshold.toInt(),
                              );
                        }

                        if (ctx.mounted) Navigator.of(ctx).pop();
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

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(allBudgetsStreamProvider);

    return budgetsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(child: Text('Error loading budgets: $err')),
      data: (budgets) {
        // Filter by period type
        final filteredBudgets = budgets.where((b) {
          if (_selectedFilter == 'All') return true;
          return b.periodType.toLowerCase() == _selectedFilter.toLowerCase();
        }).toList();

        final totalBudgetCents = budgets
            .where((b) => !b.isPaused)
            .fold<int>(0, (sum, b) => sum + b.amountCents);

        int totalSpentInActiveBudgets = 0;
        for (final b in budgets.where((b) => !b.isPaused)) {
          final progress = BudgetProgress.compute(
            budget: b,
            transactions: widget.allTransactions,
          );
          totalSpentInActiveBudgets += progress.spentCents;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionHeader(
                  title: 'Spending Budgets',
                  subtitle: 'Daily, weekly & monthly spending caps',
                ),
                TextButton.icon(
                  onPressed: () => _showBudgetDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Budget'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryIndigo,
                  ),
                ),
              ],
            ),
            if (budgets.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.darkCardSurface
                      : AppColors.lightCardSurface,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(
                    color: widget.isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Active Cap',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: widget.isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCents(totalBudgetCents),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Spent in Active',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: widget.isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCents(totalSpentInActiveBudgets),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: totalSpentInActiveBudgets > totalBudgetCents
                                ? AppColors.errorCoral
                                : AppColors.primaryIndigo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Period filter pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Daily', 'Weekly', 'Monthly'].map((filter) {
                  final isSel = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSel,
                      selectedColor: widget.isDark
                          ? AppColors.darkSoftIndigo
                          : AppColors.lightSoftIndigo,
                      checkmarkColor: AppColors.primaryIndigo,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel
                            ? AppColors.primaryIndigo
                            : (widget.isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText),
                      ),
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            if (filteredBudgets.isEmpty)
              EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No budgets created',
                message:
                    'Set daily, weekly, or monthly spending limits to prevent budget overruns.',
                actionLabel: 'Create First Budget',
                onActionPressed: () => _showBudgetDialog(),
              )
            else
              ...filteredBudgets.map((b) {
                final progress = BudgetProgress.compute(
                  budget: b,
                  transactions: widget.allTransactions,
                );

                final isOver = progress.isOverBudget;
                final isWarning = progress.hasReachedAlertThreshold && !isOver;

                Color statusColor;
                String statusText;
                if (b.isPaused) {
                  statusColor = widget.isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText;
                  statusText = 'Paused';
                } else if (isOver) {
                  statusColor = AppColors.errorCoral;
                  statusText = 'Over Budget';
                } else if (isWarning) {
                  statusColor = AppColors.warningAmber;
                  statusText = '${b.alertThresholdPercent}% Limit Reached';
                } else {
                  statusColor = AppColors.successMint;
                  statusText = 'On Track';
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppColors.darkCardSurface
                        : AppColors.lightCardSurface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: isOver
                          ? AppColors.errorCoral.withValues(alpha: 0.5)
                          : isWarning
                              ? AppColors.warningAmber.withValues(alpha: 0.5)
                              : (widget.isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                      width: isOver || isWarning ? 1.5 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  b.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isDark
                                        ? AppColors.darkPrimaryText
                                        : AppColors.lightPrimaryText,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.isDark
                                        ? AppColors.darkSoftIndigo
                                        : AppColors.lightSoftIndigo,
                                    borderRadius: AppRadius.pillRadius,
                                  ),
                                  child: Text(
                                    b.periodType.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryIndigo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              size: 18,
                              color: widget.isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                            onSelected: (action) async {
                              if (action == 'edit') {
                                _showBudgetDialog(existingBudget: b);
                              } else if (action == 'pause') {
                                await ref
                                    .read(financeRepositoryProvider)
                                    .togglePauseBudget(b.id);
                              } else if (action == 'delete') {
                                await ref
                                    .read(financeRepositoryProvider)
                                    .deleteBudget(b.id);
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: const [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit Budget'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'pause',
                                child: Row(
                                  children: [
                                    Icon(
                                      b.isPaused
                                          ? Icons.play_arrow_outlined
                                          : Icons.pause_outlined,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(b.isPaused ? 'Resume Budget' : 'Pause Budget'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: const [
                                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete Budget', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (b.category != null && b.category!.isNotEmpty && b.category != 'All')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Category: ${b.category}',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatCents(progress.spentCents)} / ${_formatCents(b.amountCents)}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            '${progress.percentageUsed.toStringAsFixed(1)}% Used',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: AppRadius.pillRadius,
                        child: LinearProgressIndicator(
                          value: (progress.percentageUsed / 100.0).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: widget.isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isOver
                                ? 'Over by ${_formatCents(progress.spentCents - b.amountCents)}'
                                : '${_formatCents(progress.remainingCents)} remaining',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOver
                                  ? AppColors.errorCoral
                                  : AppColors.successMint,
                            ),
                          ),
                          Text(
                            'Alert at ${b.alertThresholdPercent}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
