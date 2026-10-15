import '../../../../core/database/app_database.dart';

/// Represents a debt entry (Borrowed or Lent) alongside its logged repayments.
class MoneyDebtWithRepayments {
  final MoneyDebtEntry debt;
  final List<MoneyDebtRepaymentEntry> repayments;

  const MoneyDebtWithRepayments({
    required this.debt,
    this.repayments = const [],
  });

  bool get isLent => debt.type.toLowerCase() == 'lent';
  bool get isBorrowed => debt.type.toLowerCase() == 'borrowed';
  bool get isSettled => debt.remainingAmountCents <= 0;

  bool get isOverdue {
    if (isSettled || debt.dueDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(debt.dueDate!);
  }

  int get totalRepaidCents {
    return repayments.fold<int>(0, (sum, r) => sum + r.amountCents);
  }

  double get repaymentProgressPercent {
    if (debt.initialAmountCents <= 0) return 100.0;
    final repaid = debt.initialAmountCents - debt.remainingAmountCents;
    return ((repaid / debt.initialAmountCents) * 100.0).clamp(0.0, 100.0);
  }

  int get daysUntilDue {
    if (debt.dueDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      debt.dueDate!.year,
      debt.dueDate!.month,
      debt.dueDate!.day,
    );
    return due.difference(today).inDays;
  }
}

/// Aggregated financial metrics for Borrowed and Lent money tracking.
class MoneyTrackerSummary {
  final int totalLentRemainingCents;
  final int totalBorrowedRemainingCents;
  final int netBalanceCents; // Lent (Receivable) - Borrowed (Payable)
  final int activeLentCount;
  final int activeBorrowedCount;
  final int overdueCount;
  final int settledCount;

  const MoneyTrackerSummary({
    required this.totalLentRemainingCents,
    required this.totalBorrowedRemainingCents,
    required this.netBalanceCents,
    required this.activeLentCount,
    required this.activeBorrowedCount,
    required this.overdueCount,
    required this.settledCount,
  });

  factory MoneyTrackerSummary.compute(List<MoneyDebtEntry> debts) {
    int lentRemaining = 0;
    int borrowedRemaining = 0;
    int activeLent = 0;
    int activeBorrowed = 0;
    int overdue = 0;
    int settled = 0;

    final now = DateTime.now();

    for (final d in debts) {
      final isSettled = d.remainingAmountCents <= 0;
      if (isSettled) {
        settled++;
        continue;
      }

      final isOverdue = d.dueDate != null && now.isAfter(d.dueDate!);
      if (isOverdue) overdue++;

      if (d.type.toLowerCase() == 'lent') {
        lentRemaining += d.remainingAmountCents;
        activeLent++;
      } else {
        borrowedRemaining += d.remainingAmountCents;
        activeBorrowed++;
      }
    }

    return MoneyTrackerSummary(
      totalLentRemainingCents: lentRemaining,
      totalBorrowedRemainingCents: borrowedRemaining,
      netBalanceCents: lentRemaining - borrowedRemaining,
      activeLentCount: activeLent,
      activeBorrowedCount: activeBorrowed,
      overdueCount: overdue,
      settledCount: settled,
    );
  }
}
