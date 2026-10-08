import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/balance_card.dart';
import '../../../core/widgets/summary_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Finance Management Screen Foundation.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _currentTab = 0; // 0: Overview, 1: Plan, 2: Analytics, 3: Compare
  final List<String> _tabs = ['Overview', 'Plan', 'Analytics', 'Compare'];

  void _showAddTransactionDialog({required bool isIncome}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedAccount = 'Cash';

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
                    keyboardType: TextInputType.number,
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
                          onPressed: () =>
                              setModalState(() => selectedAccount = 'Cash'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedAccount == 'Cash'
                                ? (isDark
                                      ? AppColors.darkSoftIndigo
                                      : AppColors.lightSoftIndigo)
                                : Colors.transparent,
                            side: BorderSide(
                              color: selectedAccount == 'Cash'
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
                          onPressed: () =>
                              setModalState(() => selectedAccount = 'Card'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedAccount == 'Card'
                                ? (isDark
                                      ? AppColors.darkSoftIndigo
                                      : AppColors.lightSoftIndigo)
                                : Colors.transparent,
                            side: BorderSide(
                              color: selectedAccount == 'Card'
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
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isIncome
                                ? 'Income recorded successfully'
                                : 'Expense recorded successfully',
                          ),
                        ),
                      );
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

  Widget _buildOverviewTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Balance Hero Card
        BalanceCard(
          title: 'Total Liquid Balance',
          amount: 'Rs. 53,700',
          subtitle: 'Combined Cash & Card holdings',
          icon: Icons.account_balance_wallet_rounded,
          gradient: AppGradients.finance,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: BalanceCard(
                title: 'Cash',
                amount: 'Rs. 8,500',
                subtitle: 'Liquid Cash',
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BalanceCard(
                title: 'Card',
                amount: 'Rs. 45,200',
                subtitle: 'Bank Account',
                icon: Icons.credit_card_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Income vs Expense Summary
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'October Income',
                value: 'Rs. 120,000',
                subtitle: 'Salary & freelance',
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
                title: 'October Expenses',
                value: 'Rs. 66,300',
                subtitle: '55.2% of income',
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
        // Action buttons
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
          subtitle: 'Latest financial movements',
        ),
        _buildTransactionItem(
          title: 'Supermarket Grocery',
          category: 'Food',
          account: 'Card',
          date: 'Today, 2:30 PM',
          amount: '- Rs. 4,850',
          isExpense: true,
          isDark: isDark,
        ),
        _buildTransactionItem(
          title: 'Freelance Design Milestone',
          category: 'Income',
          account: 'Card',
          date: 'Yesterday',
          amount: '+ Rs. 35,000',
          isExpense: false,
          isDark: isDark,
        ),
        _buildTransactionItem(
          title: 'Fuel refuel',
          category: 'Transport',
          account: 'Cash',
          date: 'Oct 06',
          amount: '- Rs. 2,500',
          isExpense: true,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String category,
    required String account,
    required String date,
    required String amount,
    required bool isExpense,
    required bool isDark,
  }) {
    final surfaceColor = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isExpense
                  ? (isDark
                        ? AppColors.darkSoftCoral
                        : AppColors.lightSoftCoral)
                  : (isDark ? AppColors.darkSoftMint : AppColors.lightSoftMint),
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(
              isExpense
                  ? Icons.arrow_outward_rounded
                  : Icons.arrow_downward_rounded,
              color: isExpense ? AppColors.errorCoral : AppColors.successMint,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                  '$category • $account • $date',
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
            amount,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isExpense ? AppColors.errorCoral : AppColors.successMint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTab(bool isDark) {
    final surfaceColor = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Monthly Budget Plan',
          subtitle: 'October Budget: Rs. 80,000',
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget Used',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Rs. 66,300 / Rs. 80,000 (82%)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.errorCoral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: AppRadius.pillRadius,
                child: LinearProgressIndicator(
                  value: 0.82,
                  minHeight: 10,
                  backgroundColor: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.primaryIndigo,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Rs. 13,700 remaining for the next 23 days.',
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
        const SizedBox(height: 16),
        SectionHeader(title: 'Category Allocations'),
        _buildBudgetAllocationRow(
          'Food & Dining',
          'Rs. 24,000',
          'Rs. 30,000',
          0.8,
          isDark,
        ),
        _buildBudgetAllocationRow(
          'Transport & Fuel',
          'Rs. 11,500',
          'Rs. 15,000',
          0.76,
          isDark,
        ),
        _buildBudgetAllocationRow(
          'Utilities & Internet',
          'Rs. 18,000',
          'Rs. 20,000',
          0.9,
          isDark,
        ),
        _buildBudgetAllocationRow(
          'Entertainment',
          'Rs. 12,800',
          'Rs. 15,000',
          0.85,
          isDark,
        ),
      ],
    );
  }

  Widget _buildBudgetAllocationRow(
    String category,
    String spent,
    String total,
    double progress,
    bool isDark,
  ) {
    final surfaceColor = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              Text(
                '$spent / $total',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppRadius.pillRadius,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation(
                progress > 0.85 ? AppColors.errorCoral : AppColors.accentCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Spending Breakdown',
          subtitle: 'Visual categorization for October',
        ),
        SummaryCard(
          title: 'Highest Category',
          value: 'Food & Dining (36.2%)',
          subtitle: 'Rs. 24,000 spent this month',
          icon: Icons.pie_chart_outline_rounded,
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Average Daily Spend',
          value: 'Rs. 2,210 / day',
          subtitle: 'Well within projected daily target',
          icon: Icons.trending_up_rounded,
        ),
      ],
    );
  }

  Widget _buildCompareTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Month-over-Month Comparison',
          subtitle: 'October vs September 2026',
        ),
        SummaryCard(
          title: 'Expense Variation',
          value: '- 8.4% Decrease',
          subtitle: 'Saved Rs. 6,100 compared to last month',
          icon: Icons.savings_outlined,
          iconColor: AppColors.successMint,
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Income Variation',
          value: '+ 15.0% Increase',
          subtitle: 'Boosted by freelance milestone',
          icon: Icons.show_chart_rounded,
          iconColor: AppColors.primaryIndigo,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              eyebrow: 'Income & Expense',
              title: 'Personal Finance',
              subtitle: 'Keep track of cash, card and budgets offline',
              gradient: AppGradients.finance,
            ),
          ),
          // In-page Tab switcher
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_currentTab == 0) _buildOverviewTab(isDark),
                if (_currentTab == 1) _buildPlanTab(isDark),
                if (_currentTab == 2) _buildAnalyticsTab(isDark),
                if (_currentTab == 3) _buildCompareTab(isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
