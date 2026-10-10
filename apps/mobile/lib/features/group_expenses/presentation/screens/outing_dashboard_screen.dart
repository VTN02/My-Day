import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../providers/group_expenses_providers.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/expense_item_tile.dart';
import '../widgets/member_avatar_tile.dart';
import '../widgets/settlement_tile.dart';

/// Screen 4: Outing Dashboard Screen with 4 in-page tabs (Overview, Expenses, Balances, Activity).
class OutingDashboardScreen extends ConsumerStatefulWidget {
  final String outingId;

  const OutingDashboardScreen({super.key, required this.outingId});

  @override
  ConsumerState<OutingDashboardScreen> createState() =>
      _OutingDashboardScreenState();
}

class _OutingDashboardScreenState extends ConsumerState<OutingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatAmount(int minor) {
    final val = minor / 100.0;
    return 'Rs. ${val.toStringAsFixed(minor % 100 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(
      outingSummaryStreamProvider(widget.outingId),
    );

    return summaryAsync.when(
      data: (summary) {
        if (summary == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Outing Not Found')),
            body: const Center(
              child: Text('This outing may have been removed.'),
            ),
          );
        }

        final outing = summary.outing;
        final memberCount = summary.memberCount;
        final totalSpentMinor = summary.totalSpentMinor;
        final budgetMinor = outing.budgetMinor;
        final remainingMinor = summary.budgetRemainingMinor;
        final progressRatio = summary.budgetUsageRatio;
        final progressPercent = (progressRatio * 100).round();

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: GradientHeader(
                    eyebrow: 'MyDay Split • ${outing.currencyCode}',
                    title: outing.title,
                    subtitle:
                        '$memberCount Friends • Date: ${DateFormat('MMM d, yyyy').format(outing.outingDate)}',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Manage Friends',
                          icon: const Icon(
                            Icons.group_add_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () =>
                              context.push('/split/${outing.id}/members'),
                        ),
                        IconButton(
                          tooltip: 'Settings',
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () =>
                              context.push('/split/${outing.id}/settings'),
                        ),
                      ],
                    ),
                    bottomChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Spent: ${_formatAmount(totalSpentMinor)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Budget: ${_formatAmount(budgetMinor)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: AppRadius.pillRadius,
                          child: Container(
                            height: 8,
                            color: Colors.white.withValues(alpha: 0.25),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progressRatio.clamp(0.0, 1.0),
                              child: Container(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Remaining: ${_formatAmount(remainingMinor)}',
                              style: TextStyle(
                                color: remainingMinor < 0
                                    ? AppColors.errorCoral
                                    : Colors.white.withValues(alpha: 0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Progress: $progressPercent%',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primaryIndigo,
                      indicatorWeight: 3,
                      labelColor: AppColors.primaryIndigo,
                      unselectedLabelColor: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Expenses'),
                        Tab(text: 'Balances'),
                        Tab(text: 'Activity'),
                      ],
                    ),
                    isDark
                        ? AppColors.darkBackground
                        : AppColors.lightBackground,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(summary: summary),
                _ExpensesTab(outingId: outing.id),
                _BalancesTab(summary: summary),
                _ActivityTab(outingId: outing.id),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/split/${outing.id}/expenses/add'),
            backgroundColor: AppColors.primaryIndigo,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text(
              'Add Expense',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) =>
          Scaffold(body: Center(child: Text('Error loading dashboard: $err'))),
    );
  }
}

// Delegate for pinned TabBar in NestedScrollView
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _bgColor;

  _SliverAppBarDelegate(this._tabBar, this._bgColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _bgColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// Tab 1: Overview
class _OverviewTab extends StatelessWidget {
  final dynamic summary;

  const _OverviewTab({required this.summary});

  String _formatAmount(int minor) {
    final val = minor / 100.0;
    return 'Rs. ${val.toStringAsFixed(minor % 100 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myBal = summary.myBalance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Your Balance Card
        if (myBal != null)
          Container(
            padding: const EdgeInsets.all(18),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Balance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      myBal.isSettled
                          ? 'Settled'
                          : (myBal.isCreditor
                                ? '+${_formatAmount(myBal.netBalanceMinor)}'
                                : '-${_formatAmount(myBal.outstandingDebtMinor)}'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: myBal.isSettled
                            ? AppColors.primaryIndigo
                            : (myBal.isCreditor
                                  ? AppColors.successMint
                                  : AppColors.errorCoral),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      myBal.isSettled
                          ? 'All your shares are balanced'
                          : (myBal.isCreditor
                                ? 'You should receive this from friends'
                                : 'You owe this amount to the group'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/split/${summary.outing.id}/settle'),
                  icon: const Icon(Icons.handshake_outlined, size: 18),
                  label: const Text('Settle Up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryIndigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Budget Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardSurface
                : AppColors.lightCardSurface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: BudgetProgressBar(
            spentMinor: summary.totalSpentMinor,
            budgetMinor: summary.outing.budgetMinor,
            currency: summary.outing.currencyCode,
          ),
        ),
        const SizedBox(height: 16),

        // Quick Stats Row
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Friends',
                value: '${summary.memberCount}',
                subtitle: 'Attending',
                icon: Icons.groups_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Share / Person',
                value: _formatAmount(summary.totalSharePerPersonMinor),
                subtitle: 'Equal average',
                icon: Icons.pie_chart_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/split/${summary.outing.id}/members'),
                icon: const Icon(Icons.people_outline, size: 18),
                label: const Text('Manage Friends'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/split/${summary.outing.id}/settlements'),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Repayment History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.cardRadius,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                ),
              ),
              Icon(icon, size: 18, color: AppColors.primaryIndigo),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

// Tab 2: Expenses
class _ExpensesTab extends ConsumerWidget {
  final String outingId;

  const _ExpensesTab({required this.outingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(outingExpensesStreamProvider(outingId));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses recorded yet',
            message:
                'Add lunch, transport, snacks, or activity expenses to split with friends.',
            actionLabel: 'Add First Expense',
            onActionPressed: () =>
                context.push('/split/$outingId/expenses/add'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final item = expenses[index];
            return ExpenseItemTile(
              item: item,
              onTap: () =>
                  context.push('/split/$outingId/expenses/${item.expense.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

// Tab 3: Balances
class _BalancesTab extends StatelessWidget {
  final dynamic summary;

  const _BalancesTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balances = summary.memberBalances;
    final suggested = summary.suggestedSettlements;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Suggested Settlements Section
        if (suggested.isNotEmpty) ...[
          const Text(
            'Suggested Settlement Plan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Optimal transactions to settle all group balances completely:',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 12),
          for (final s in suggested)
            SettlementTile(
              settlement: s,
              onSettleTap: () => context.push(
                '/split/${summary.outing.id}/settle?from=${s.fromMemberId}&to=${s.toMemberId}&amount=${s.amountMinor}',
              ),
            ),
          const SizedBox(height: 20),
        ],

        // Member Balances Section
        const Text(
          'Member Balances',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Paid vs share breakdown for each participant:',
          style: TextStyle(
            fontSize: 12.5,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
        const SizedBox(height: 12),
        for (final b in balances) MemberAvatarTile(balance: b),
      ],
    );
  }
}

// Tab 4: Activity
class _ActivityTab extends ConsumerWidget {
  final String outingId;

  const _ActivityTab({required this.outingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expensesAsync = ref.watch(outingExpensesStreamProvider(outingId));
    final settlementsAsync = ref.watch(
      outingSettlementsStreamProvider(outingId),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Activity feed combining expenses and settlements
        settlementsAsync.when(
          data: (settlements) {
            return expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty && settlements.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No activity yet',
                    message:
                        'Activity such as created expenses and repayments will appear here.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (settlements.isNotEmpty) ...[
                      const Text(
                        'Repayment Ledger',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final st in settlements)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardSurface
                                : AppColors.lightCardSurface,
                            borderRadius: AppRadius.cardRadius,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                st.status == 'completed'
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.cancel_outlined,
                                color: st.status == 'completed'
                                    ? AppColors.successMint
                                    : AppColors.errorCoral,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Repayment: Rs. ${(st.amountMinor / 100).toStringAsFixed(0)} on ${DateFormat('MMM d').format(st.settlementDate)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                st.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: st.status == 'completed'
                                      ? AppColors.successMint
                                      : AppColors.errorCoral,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      'Expense Activity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final exp in expenses)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardSurface
                              : AppColors.lightCardSurface,
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_shopping_cart_rounded,
                              color: AppColors.primaryIndigo,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${exp.expense.title} • Paid by ${exp.payer.displayName}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'Rs. ${(exp.expense.amountMinor / 100).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const SizedBox.shrink(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
