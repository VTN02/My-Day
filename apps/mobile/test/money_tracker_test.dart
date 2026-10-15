import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/repositories/money_tracker_repository.dart';
import 'package:mobile/features/money_tracker/domain/models/money_debt_model.dart';

void main() {
  group('MoneyTrackerSummary Calculations', () {
    test('Computes net position, active counts, and overdue debts accurately', () {
      final now = DateTime.now();
      final debts = [
        // Lent: Rs. 5,000 remaining of Rs. 10,000
        MoneyDebtEntry(
          id: 'd1',
          type: 'lent',
          personName: 'Kasun',
          initialAmountCents: 1000000,
          remainingAmountCents: 500000,
          currency: 'LKR',
          issueDate: now.subtract(const Duration(days: 10)),
          dueDate: now.add(const Duration(days: 5)),
          reminderEnabled: true,
          reminderOption: 'on_due_date',
          status: 'partially_paid',
          createdAt: now,
          updatedAt: now,
        ),
        // Lent: Rs. 3,000 overdue
        MoneyDebtEntry(
          id: 'd2',
          type: 'lent',
          personName: 'Nimal',
          initialAmountCents: 300000,
          remainingAmountCents: 300000,
          currency: 'LKR',
          issueDate: now.subtract(const Duration(days: 20)),
          dueDate: now.subtract(const Duration(days: 2)), // Overdue
          reminderEnabled: true,
          reminderOption: 'on_due_date',
          status: 'unpaid',
          createdAt: now,
          updatedAt: now,
        ),
        // Borrowed: Rs. 4,000 remaining of Rs. 4,000
        MoneyDebtEntry(
          id: 'd3',
          type: 'borrowed',
          personName: 'Amma',
          initialAmountCents: 400000,
          remainingAmountCents: 400000,
          currency: 'LKR',
          issueDate: now.subtract(const Duration(days: 5)),
          dueDate: now.add(const Duration(days: 10)),
          reminderEnabled: true,
          reminderOption: 'on_due_date',
          status: 'unpaid',
          createdAt: now,
          updatedAt: now,
        ),
        // Settled debt: Rs. 0 remaining
        MoneyDebtEntry(
          id: 'd4',
          type: 'lent',
          personName: 'Sunil',
          initialAmountCents: 200000,
          remainingAmountCents: 0,
          currency: 'LKR',
          issueDate: now.subtract(const Duration(days: 30)),
          dueDate: now.subtract(const Duration(days: 15)),
          reminderEnabled: false,
          reminderOption: 'on_due_date',
          status: 'settled',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = MoneyTrackerSummary.compute(debts);

      // Lent remaining: 5000 + 3000 = 8000
      expect(summary.totalLentRemainingCents, equals(800000));
      // Borrowed remaining: 4000
      expect(summary.totalBorrowedRemainingCents, equals(400000));
      // Net position: 8000 - 4000 = +4000 (Receivable)
      expect(summary.netBalanceCents, equals(400000));
      expect(summary.activeLentCount, equals(2));
      expect(summary.activeBorrowedCount, equals(1));
      expect(summary.overdueCount, equals(1));
      expect(summary.settledCount, equals(1));
    });
  });

  group('MoneyDebtWithRepayments Model Helpers', () {
    test('Calculates repayment progress and overdue status correctly', () {
      final now = DateTime.now();
      final debt = MoneyDebtEntry(
        id: 'd1',
        type: 'lent',
        personName: 'Dilshan',
        initialAmountCents: 1000000, // Rs. 10,000
        remainingAmountCents: 300000, // Rs. 3,000
        currency: 'LKR',
        issueDate: now.subtract(const Duration(days: 14)),
        dueDate: now.subtract(const Duration(days: 1)), // Overdue
        reminderEnabled: true,
        reminderOption: 'on_due_date',
        status: 'partially_paid',
        createdAt: now,
        updatedAt: now,
      );

      final repayments = [
        MoneyDebtRepaymentEntry(
          id: 'r1',
          debtId: 'd1',
          amountCents: 400000, // Rs. 4,000
          repaymentDate: now.subtract(const Duration(days: 7)),
          createdAt: now,
        ),
        MoneyDebtRepaymentEntry(
          id: 'r2',
          debtId: 'd1',
          amountCents: 300000, // Rs. 3,000
          repaymentDate: now.subtract(const Duration(days: 2)),
          createdAt: now,
        ),
      ];

      final model = MoneyDebtWithRepayments(debt: debt, repayments: repayments);

      expect(model.isLent, isTrue);
      expect(model.isBorrowed, isFalse);
      expect(model.isSettled, isFalse);
      expect(model.isOverdue, isTrue);
      expect(model.totalRepaidCents, equals(700000)); // 4000 + 3000
      expect(model.repaymentProgressPercent, closeTo(70.0, 0.01)); // (10000 - 3000)/10000 = 70%
    });
  });

  group('DriftMoneyTrackerRepository Integration', () {
    late AppDatabase db;
    late DriftMoneyTrackerRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftMoneyTrackerRepository(db);

      // Update pre-seeded account balance to Rs. 20,000 for linked testing
      await (db.update(db.financialAccountsTable)
            ..where((a) => a.id.equals('account_cash')))
          .write(
        const FinancialAccountsTableCompanion(
          openingBalanceCents: Value(2000000),
          currentBalanceCents: Value(2000000),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Create debt with linked account updates cash balance', () async {
      final debtId = await repo.createDebt(
        type: 'lent',
        personName: 'Raveen',
        initialAmountCents: 500000, // Rs. 5,000
        issueDate: DateTime.now(),
        linkedAccountId: 'account_cash',
        updateAccountBalance: true,
      );

      final debt = await repo.getDebt(debtId);
      expect(debt, isNotNull);
      expect(debt!.remainingAmountCents, equals(500000));
      expect(debt.status, equals('unpaid'));

      // Check account balance: was 20,000, lent out 5,000 -> 15,000
      final account = await (db.select(db.financialAccountsTable)
            ..where((a) => a.id.equals('account_cash')))
          .getSingle();
      expect(account.currentBalanceCents, equals(1500000));
    });

    test('Partial repayment updates status and account balance correctly', () async {
      final debtId = await repo.createDebt(
        type: 'lent',
        personName: 'Malith',
        initialAmountCents: 1000000, // Rs. 10,000
        issueDate: DateTime.now(),
        linkedAccountId: 'account_cash',
        updateAccountBalance: false, // Don't deduct initial
      );

      // Record partial repayment of Rs. 4,000
      await repo.recordRepayment(
        debtId: debtId,
        amountCents: 400000,
        repaymentDate: DateTime.now(),
        notes: 'Bank Transfer installment 1',
        linkedAccountId: 'account_cash',
        updateAccountBalance: true,
      );

      final debtAfterFirst = await repo.getDebt(debtId);
      expect(debtAfterFirst!.remainingAmountCents, equals(600000)); // 6,000 left
      expect(debtAfterFirst.status, equals('partially_paid'));

      // Account was 20,000, repayment came in +4,000 -> 24,000
      final account1 = await (db.select(db.financialAccountsTable)
            ..where((a) => a.id.equals('account_cash')))
          .getSingle();
      expect(account1.currentBalanceCents, equals(2400000));

      // Record final repayment of Rs. 6,000
      await repo.recordRepayment(
        debtId: debtId,
        amountCents: 600000,
        repaymentDate: DateTime.now(),
        notes: 'Final settlement',
        linkedAccountId: 'account_cash',
        updateAccountBalance: true,
      );

      final debtSettled = await repo.getDebt(debtId);
      expect(debtSettled!.remainingAmountCents, equals(0));
      expect(debtSettled.status, equals('settled'));

      // Check repayments list
      final repayments = await repo.getRepayments(debtId);
      expect(repayments.length, equals(2));
    });

    test('Deleting debt cascades and deletes associated repayment logs', () async {
      final debtId = await repo.createDebt(
        type: 'borrowed',
        personName: 'Kavindu',
        initialAmountCents: 300000,
        issueDate: DateTime.now(),
      );

      await repo.recordRepayment(
        debtId: debtId,
        amountCents: 100000,
        repaymentDate: DateTime.now(),
      );

      final repsBefore = await repo.getRepayments(debtId);
      expect(repsBefore.length, equals(1));

      // Delete debt
      await repo.deleteDebt(debtId);

      final debtAfter = await repo.getDebt(debtId);
      expect(debtAfter, isNull);

      final repsAfter = await repo.getRepayments(debtId);
      expect(repsAfter, isEmpty);
    });
  });
}
