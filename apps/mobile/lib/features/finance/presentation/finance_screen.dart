import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/balance_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/summary_card.dart';
import 'finance_charts.dart';

/// Finance Management Screen connected to Drift SQLite repository.
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  int _currentTab = 0; // 0: Overview, 1: Plan, 2: Analytics, 3: Compare
  final List<String> _tabs = ['Overview', 'Plan', 'Analytics', 'Compare'];

  String _formatCents(int cents) {
    final val = cents / 100.0;
    return 'Rs. ${val.toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
  }

  void _showAddTransactionDialog({required bool isIncome}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedAccount = 'account_cash';
    String selectedCategory = isIncome ? 'Salary' : 'Food';

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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isIncome ? 'Add Income' : 'Record Expense',
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
                    label: 'Description',
                    hint: isIncome
                        ? 'e.g. Monthly Salary, Freelance'
                        : 'e.g. Groceries, Transport',
                    controller: titleController,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Amount (LKR)',
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    controller: amountController,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setModalState(
                            () => selectedAccount = 'account_cash',
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedAccount == 'account_cash'
                                ? (isDark
                                      ? AppColors.darkSoftIndigo
                                      : AppColors.lightSoftIndigo)
                                : Colors.transparent,
                            side: BorderSide(
                              color: selectedAccount == 'account_cash'
                                  ? AppColors.primaryIndigo
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: const Text('Cash'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setModalState(
                            () => selectedAccount = 'account_card',
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedAccount == 'account_card'
                                ? (isDark
                                      ? AppColors.darkSoftIndigo
                                      : AppColors.lightSoftIndigo)
                                : Colors.transparent,
                            side: BorderSide(
                              color: selectedAccount == 'account_card'
                                  ? AppColors.primaryIndigo
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: const Text('Card'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: isIncome ? 'Save Income' : 'Save Expense',
                    backgroundColor: isIncome
                        ? AppColors.successMint
                        : AppColors.errorCoral,
                    isFullWidth: true,
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final amountRaw =
                          double.tryParse(amountController.text.trim()) ?? 0.0;
                      if (title.isEmpty || amountRaw <= 0) return;

                      final amountCents = (amountRaw * 100).round();

                      await ref
                          .read(financeRepositoryProvider)
                          .recordTransaction(
                            accountId: selectedAccount,
                            type: isIncome ? 'income' : 'expense',
                            amountCents: amountCents,
                            category: selectedCategory,
                            description: title,
                            transactionDate: DateTime.now(),
                          );

                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewTab(
    bool isDark,
    List<FinancialAccountEntry> accounts,
    List<FinancialTransactionEntry> transactions,
  ) {
    final cashAccount = accounts.cast<FinancialAccountEntry?>().firstWhere(
      (a) => a?.id == 'account_cash',
      orElse: () => accounts.isNotEmpty ? accounts.first : null,
    );
    final cardAccount = accounts.cast<FinancialAccountEntry?>().firstWhere(
      (a) => a?.id == 'account_card',
      orElse: () => accounts.isNotEmpty ? accounts.last : null,
    );

    final cashBalance = cashAccount?.currentBalanceCents ?? 0;
    final cardBalance = cardAccount?.currentBalanceCents ?? 0;
    final totalLiquidCents = cashBalance + cardBalance;

    // Monthly income / expense sums
    var totalIncomeCents = 0;
    var totalExpenseCents = 0;
    for (final tx in transactions) {
      if (tx.type == 'income') {
        totalIncomeCents += tx.amountCents;
      } else {
        totalExpenseCents += tx.amountCents;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BalanceCard(
          title: 'Total Liquid Balance',
          amount: _formatCents(totalLiquidCents),
          subtitle: 'Combined Cash & Card holdings in SQLite',
          icon: Icons.account_balance_wallet_rounded,
          gradient: AppGradients.finance,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: BalanceCard(
                title: 'Cash',
                amount: _formatCents(cashBalance),
                subtitle: 'Liquid Cash',
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BalanceCard(
                title: 'Card',
                amount: _formatCents(cardBalance),
                subtitle: 'Bank / Card',
                icon: Icons.credit_card_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total Income',
                value: _formatCents(totalIncomeCents),
                subtitle:
                    '${transactions.where((t) => t.type == 'income').length} entries',
                icon: Icons.arrow_downward_rounded,
                iconColor: AppColors.successMint,
                iconBackgroundColor: isDark
                    ? AppColors.darkSoftMint
                    : AppColors.lightSoftMint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Total Expenses',
                value: _formatCents(totalExpenseCents),
                subtitle:
                    '${transactions.where((t) => t.type == 'expense').length} entries',
                icon: Icons.arrow_upward_rounded,
                iconColor: AppColors.errorCoral,
                iconBackgroundColor: isDark
                    ? AppColors.darkSoftCoral
                    : AppColors.lightSoftCoral,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                text: 'Add Income',
                icon: Icons.add,
                backgroundColor: AppColors.successMint,
                onPressed: () => _showAddTransactionDialog(isIncome: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                text: 'Add Expense',
                icon: Icons.remove,
                backgroundColor: AppColors.errorCoral,
                onPressed: () => _showAddTransactionDialog(isIncome: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Recent Transactions',
          subtitle: 'Persistent SQLite financial records',
        ),
        if (transactions.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            message:
                'Track daily expenses or income to view real balance updates.',
            actionLabel: 'Record Expense',
            onActionPressed: () => _showAddTransactionDialog(isIncome: false),
          )
        else
          ...transactions.take(10).map((tx) {
            final isExp = tx.type == 'expense';
            return Container(
              key: ValueKey(tx.id),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardSurface
                    : AppColors.lightCardSurface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isExp
                          ? (isDark
                                ? AppColors.darkSoftCoral
                                : AppColors.lightSoftCoral)
                          : (isDark
                                ? AppColors.darkSoftMint
                                : AppColors.lightSoftMint),
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Icon(
                      isExp
                          ? Icons.arrow_outward_rounded
                          : Icons.arrow_downward_rounded,
                      color: isExp
                          ? AppColors.errorCoral
                          : AppColors.successMint,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.description,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tx.category} • ${tx.accountId == 'account_cash' ? 'Cash' : 'Card'}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isExp ? '-' : '+'} ${_formatCents(tx.amountCents)}',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isExp
                          ? AppColors.errorCoral
                          : AppColors.successMint,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    onPressed: () => ref
                        .read(financeRepositoryProvider)
                        .deleteTransaction(tx.id),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showSetBudgetDialog(int currentBudgetCents) {
    final controller = TextEditingController(
      text: (currentBudgetCents / 100.0).toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Set Monthly Budget Target',
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
                label: 'Monthly Target (LKR)',
                hint: 'e.g. 80000',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                controller: controller,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Save Budget Target',
                icon: Icons.check,
                isFullWidth: true,
                onPressed: () async {
                  final raw = double.tryParse(controller.text.trim()) ?? 0.0;
                  if (raw <= 0) return;
                  final now = DateTime.now();
                  final targetCents = (raw * 100).round();
                  await ref
                      .read(financeRepositoryProvider)
                      .setMonthlyBudget(now.year, now.month, targetCents);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
        return Icons.restaurant_outlined;
      case 'transport':
      case 'fuel':
        return Icons.directions_car_outlined;
      case 'utilities':
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'health':
      case 'medical':
        return Icons.medical_services_outlined;
      case 'salary':
        return Icons.payments_outlined;
      case 'freelance':
      case 'investment':
        return Icons.trending_up_rounded;
      default:
        return Icons.category_outlined;
    }
  }

  String _getMonthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return names[month - 1];
    return '';
  }

  Widget _buildPlanTab(
    bool isDark,
    List<FinancialTransactionEntry> allTransactions,
    MonthlyBudgetEntry? budgetEntry,
  ) {
    final now = DateTime.now();
    final thisMonthTx = allTransactions
        .where(
          (t) =>
              t.transactionDate.year == now.year &&
              t.transactionDate.month == now.month,
        )
        .toList();
    final monthExpensesCents = thisMonthTx
        .where((t) => t.type == 'expense')
        .fold<int>(0, (sum, t) => sum + t.amountCents);
    final targetBudgetCents = budgetEntry?.totalBudgetCents ?? 8000000;
    final ratio = targetBudgetCents > 0
        ? (monthExpensesCents / targetBudgetCents)
        : 0.0;
    final isOverBudget = monthExpensesCents > targetBudgetCents;
    final pctUsed = (ratio * 100).clamp(0, 999).toStringAsFixed(1);

    // Group expenses by category
    final categoryTotals = <String, int>{};
    for (final tx in thisMonthTx.where((t) => t.type == 'expense')) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0) + tx.amountCents;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Monthly Budget Plan',
          subtitle: '${_getMonthName(now.month)} ${now.year} Target',
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardSurface
                : AppColors.lightCardSurface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Used ($pctUsed%)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatCents(monthExpensesCents)} / ${_formatCents(targetBudgetCents)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isOverBudget
                              ? AppColors.errorCoral
                              : AppColors.primaryIndigo,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showSetBudgetDialog(targetBudgetCents),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Target', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: AppRadius.pillRadius,
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  valueColor: AlwaysStoppedAnimation(
                    isOverBudget ? AppColors.errorCoral : AppColors.primaryIndigo,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOverBudget
                        ? 'Over budget by ${_formatCents(monthExpensesCents - targetBudgetCents)}'
                        : 'Remaining: ${_formatCents(targetBudgetCents - monthExpensesCents)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOverBudget
                          ? AppColors.errorCoral
                          : AppColors.successMint,
                    ),
                  ),
                  Text(
                    '${thisMonthTx.where((t) => t.type == 'expense').length} expense logs',
                    style: TextStyle(
                      fontSize: 11.5,
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
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Category Spending',
          subtitle: 'Active month allocation breakdown',
        ),
        if (sortedCategories.isEmpty)
          EmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No expenses this month',
            message: 'Record expenses to track your category budget consumption.',
            actionLabel: 'Record Expense',
            onActionPressed: () => _showAddTransactionDialog(isIncome: false),
          )
        else
          ...sortedCategories.map((entry) {
            final catCents = entry.value;
            final catRatio = monthExpensesCents > 0
                ? (catCents / monthExpensesCents)
                : 0.0;
            final catPct = (catRatio * 100).toStringAsFixed(1);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardSurface
                    : AppColors.lightCardSurface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(entry.key),
                            size: 18,
                            color: AppColors.accentCyan,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_formatCents(catCents)} ($catPct%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value: catRatio.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accentCyan,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAnalyticsTab(
    bool isDark,
    List<FinancialTransactionEntry> allTransactions,
  ) {
    var totalInc = 0;
    var totalExp = 0;
    final catTotals = <String, int>{};
    final catCounts = <String, int>{};

    for (final tx in allTransactions) {
      if (tx.type == 'income') {
        totalInc += tx.amountCents;
      } else {
        totalExp += tx.amountCents;
        catTotals[tx.category] = (catTotals[tx.category] ?? 0) + tx.amountCents;
        catCounts[tx.category] = (catCounts[tx.category] ?? 0) + 1;
      }
    }

    final netSavings = totalInc - totalExp;
    final savingsRate = totalInc > 0
        ? ((netSavings / totalInc) * 100).clamp(-100.0, 100.0)
        : 0.0;

    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCat = sortedCats.isNotEmpty ? sortedCats.first : null;
    final topCatPct = topCat != null && totalExp > 0
        ? ((topCat.value / totalExp) * 100).toStringAsFixed(1)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Financial Analytics',
          subtitle: 'Holistic income, expense & savings metrics',
        ),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Net Savings',
                value: _formatCents(netSavings),
                subtitle: 'Savings Rate: ${savingsRate.toStringAsFixed(1)}%',
                icon: Icons.savings_outlined,
                iconColor: netSavings >= 0
                    ? AppColors.successMint
                    : AppColors.errorCoral,
                iconBackgroundColor: netSavings >= 0
                    ? (isDark
                        ? AppColors.darkSoftMint
                        : AppColors.lightSoftMint)
                    : (isDark
                        ? AppColors.darkSoftCoral
                        : AppColors.lightSoftCoral),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Top Expense',
                value: topCat != null ? '${topCat.key} ($topCatPct%)' : 'None',
                subtitle: topCat != null
                    ? _formatCents(topCat.value)
                    : 'No expenses',
                icon: Icons.pie_chart_outline_rounded,
                iconColor: AppColors.warningAmber,
                iconBackgroundColor: isDark
                    ? AppColors.darkSoftAmber
                    : AppColors.lightSoftAmber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Interactive Finance Donut and Cash Flow Charts
        if (totalExp > 0 || totalInc > 0) ...[
          FinanceExpenseDonutChart(
            categoryTotals: catTotals,
            totalExpenseCents: totalExp,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          FinanceCashFlowBarChart(
            totalIncomeCents: totalInc,
            totalExpenseCents: totalExp,
            recentTransactions: allTransactions,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
        ],

        SectionHeader(
          title: 'Historical Category Breakdown',
          subtitle: 'Ranked by total expenditure',
        ),
        if (sortedCats.isEmpty)
          EmptyState(
            icon: Icons.analytics_outlined,
            title: 'No analytics available',
            message: 'Add transactions to generate financial breakdown charts.',
            actionLabel: 'Record Expense',
            onActionPressed: () => _showAddTransactionDialog(isIncome: false),
          )
        else
          ...sortedCats.map((entry) {
            final shareRatio = totalExp > 0 ? (entry.value / totalExp) : 0.0;
            final sharePct = (shareRatio * 100).toStringAsFixed(1);
            final count = catCounts[entry.key] ?? 1;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardSurface
                    : AppColors.lightCardSurface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(entry.key),
                            size: 18,
                            color: AppColors.primaryIndigo,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '($count logs)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_formatCents(entry.value)} ($sharePct%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value: shareRatio.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryIndigo,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCompareTab(
    bool isDark,
    List<FinancialTransactionEntry> allTransactions,
  ) {
    final now = DateTime.now();
    final thisYear = now.year;
    final thisMonth = now.month;

    final prevMonthDate = DateTime(thisYear, thisMonth - 1, 1);
    final prevYear = prevMonthDate.year;
    final prevMonth = prevMonthDate.month;

    final currTx = allTransactions
        .where(
          (t) =>
              t.transactionDate.year == thisYear &&
              t.transactionDate.month == thisMonth,
        )
        .toList();
    final prevTx = allTransactions
        .where(
          (t) =>
              t.transactionDate.year == prevYear &&
              t.transactionDate.month == prevMonth,
        )
        .toList();

    final currExp = currTx
        .where((t) => t.type == 'expense')
        .fold<int>(0, (s, t) => s + t.amountCents);
    final prevExp = prevTx
        .where((t) => t.type == 'expense')
        .fold<int>(0, (s, t) => s + t.amountCents);

    final currInc = currTx
        .where((t) => t.type == 'income')
        .fold<int>(0, (s, t) => s + t.amountCents);
    final prevInc = prevTx
        .where((t) => t.type == 'income')
        .fold<int>(0, (s, t) => s + t.amountCents);

    final expVariancePct = prevExp > 0
        ? ((currExp - prevExp) / prevExp * 100)
        : 0.0;
    final incVariancePct = prevInc > 0
        ? ((currInc - prevInc) / prevInc * 100)
        : 0.0;

    final currNet = currInc - currExp;
    final prevNet = prevInc - prevExp;
    final netDiff = currNet - prevNet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Month-over-Month Comparison',
          subtitle:
              '${_getMonthName(thisMonth)} vs ${_getMonthName(prevMonth)}',
        ),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Expense Delta',
                value:
                    '${expVariancePct >= 0 ? '+' : ''}${expVariancePct.toStringAsFixed(1)}%',
                subtitle:
                    '${_formatCents(currExp)} vs ${_formatCents(prevExp)}',
                icon: expVariancePct <= 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
                iconColor: expVariancePct <= 0
                    ? AppColors.successMint
                    : AppColors.errorCoral,
                iconBackgroundColor: expVariancePct <= 0
                    ? (isDark
                        ? AppColors.darkSoftMint
                        : AppColors.lightSoftMint)
                    : (isDark
                        ? AppColors.darkSoftCoral
                        : AppColors.lightSoftCoral),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Income Delta',
                value:
                    '${incVariancePct >= 0 ? '+' : ''}${incVariancePct.toStringAsFixed(1)}%',
                subtitle:
                    '${_formatCents(currInc)} vs ${_formatCents(prevInc)}',
                icon: incVariancePct >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                iconColor: incVariancePct >= 0
                    ? AppColors.successMint
                    : AppColors.errorCoral,
                iconBackgroundColor: incVariancePct >= 0
                    ? (isDark
                        ? AppColors.darkSoftMint
                        : AppColors.lightSoftMint)
                    : (isDark
                        ? AppColors.darkSoftCoral
                        : AppColors.lightSoftCoral),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SummaryCard(
          title: 'Net Cashflow Variance',
          value: '${netDiff >= 0 ? '+' : ''}${_formatCents(netDiff)}',
          subtitle:
              'Current net (${_formatCents(currNet)}) vs Previous net (${_formatCents(prevNet)})',
          icon: Icons.compare_arrows_rounded,
          iconColor:
              netDiff >= 0 ? AppColors.successMint : AppColors.errorCoral,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardSurface
                : AppColors.lightCardSurface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.accentCyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  expVariancePct > 10
                      ? 'Expense alert: Spending has increased by over 10% compared to last month. Review discretionary spending to stay on target.'
                      : expVariancePct < 0
                          ? 'Great discipline! Expenses are lower than last month, increasing your net savings.'
                          : 'Spending pace is consistent with last month.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountsAsync = ref.watch(financialAccountsStreamProvider);
    final transactionsAsync = ref.watch(allTransactionsStreamProvider);
    final budgetAsync = ref.watch(currentMonthBudgetStreamProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              eyebrow: 'Income & Expense',
              title: 'Personal Finance',
              subtitle: 'Accurate minor currency unit arithmetic with Drift',
              gradient: AppGradients.finance,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = _currentTab == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_tabs[index]),
                        selected: isSelected,
                        selectedColor: AppColors.accentCyan,
                        backgroundColor: isDark
                            ? AppColors.darkCardSurface
                            : const Color(0xFFEFF2FA),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? AppColors.darkPrimaryText
                                    : AppColors.lightPrimaryText),
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        onSelected: (_) => setState(() => _currentTab = index),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          accountsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: LoadingState(message: 'Loading financial records...'),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('Error loading accounts: $err')),
              ),
            ),
            data: (accounts) {
              return transactionsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: LoadingState(message: 'Loading transactions...'),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('Error loading transactions: $err'),
                    ),
                  ),
                ),
                data: (transactions) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_currentTab == 0)
                          _buildOverviewTab(isDark, accounts, transactions),
                        if (_currentTab == 1)
                          _buildPlanTab(
                            isDark,
                            transactions,
                            budgetAsync.value,
                          ),
                        if (_currentTab == 2)
                          _buildAnalyticsTab(isDark, transactions),
                        if (_currentTab == 3)
                          _buildCompareTab(isDark, transactions),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Add Transaction',
        onPressed: () => _showAddTransactionDialog(isIncome: false),
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}
