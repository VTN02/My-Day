import '../../../../core/database/app_database.dart';

/// Represents calculated utilization and progress for a spending budget.
class BudgetProgress {
  final BudgetEntry budget;
  final int spentCents;
  final int remainingCents;
  final double percentageUsed;
  final bool isOverBudget;
  final bool hasReachedAlertThreshold;
  final DateTime periodStart;
  final DateTime periodEnd;

  const BudgetProgress({
    required this.budget,
    required this.spentCents,
    required this.remainingCents,
    required this.percentageUsed,
    required this.isOverBudget,
    required this.hasReachedAlertThreshold,
    required this.periodStart,
    required this.periodEnd,
  });

  /// Computes start and end timestamps based on period type and reference date.
  static (DateTime, DateTime) calculatePeriodBounds(
    String periodType,
    DateTime referenceDate,
  ) {
    switch (periodType.toLowerCase()) {
      case 'daily':
        final start = DateTime(
          referenceDate.year,
          referenceDate.month,
          referenceDate.day,
          0,
          0,
          0,
        );
        final end = DateTime(
          referenceDate.year,
          referenceDate.month,
          referenceDate.day,
          23,
          59,
          59,
          999,
        );
        return (start, end);
      case 'weekly':
        final monday = referenceDate.subtract(
          Duration(days: referenceDate.weekday - 1),
        );
        final sunday = monday.add(const Duration(days: 6));
        final start = DateTime(
          monday.year,
          monday.month,
          monday.day,
          0,
          0,
          0,
        );
        final end = DateTime(
          sunday.year,
          sunday.month,
          sunday.day,
          23,
          59,
          59,
          999,
        );
        return (start, end);
      case 'monthly':
      default:
        final start = DateTime(
          referenceDate.year,
          referenceDate.month,
          1,
          0,
          0,
          0,
        );
        final nextMonth = referenceDate.month == 12
            ? DateTime(referenceDate.year + 1, 1, 1)
            : DateTime(referenceDate.year, referenceDate.month + 1, 1);
        final end = nextMonth.subtract(const Duration(milliseconds: 1));
        return (start, end);
    }
  }

  /// Calculates actual spending and thresholds against stored transactions.
  static BudgetProgress compute({
    required BudgetEntry budget,
    required List<FinancialTransactionEntry> transactions,
    DateTime? referenceDate,
  }) {
    final ref = referenceDate ?? DateTime.now();
    final (start, end) = calculatePeriodBounds(budget.periodType, ref);

    int totalSpentCents = 0;
    for (final tx in transactions) {
      if (tx.type == 'expense' &&
          tx.transactionDate.isAfter(
            start.subtract(const Duration(milliseconds: 1)),
          ) &&
          tx.transactionDate.isBefore(
            end.add(const Duration(milliseconds: 1)),
          )) {
        if (budget.category == null ||
            budget.category == 'All' ||
            budget.category!.isEmpty ||
            tx.category.toLowerCase() == budget.category!.toLowerCase()) {
          totalSpentCents += tx.amountCents;
        }
      }
    }

    final remaining = budget.amountCents > totalSpentCents
        ? budget.amountCents - totalSpentCents
        : 0;
    final percent = budget.amountCents == 0
        ? 0.0
        : (totalSpentCents / budget.amountCents) * 100.0;
    final isOver = totalSpentCents > budget.amountCents;
    final thresholdHit = percent >= budget.alertThresholdPercent;

    return BudgetProgress(
      budget: budget,
      spentCents: totalSpentCents,
      remainingCents: remaining,
      percentageUsed: percent,
      isOverBudget: isOver,
      hasReachedAlertThreshold: thresholdHit,
      periodStart: start,
      periodEnd: end,
    );
  }
}
