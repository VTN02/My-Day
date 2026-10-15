import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/repositories/finance_repository.dart';
import 'package:mobile/features/finance/domain/models/budget_progress.dart';
import 'package:mobile/features/finance/presentation/category_dialogs.dart';

void main() {
  group('BudgetProgress & Period Calculations', () {
    final refDate = DateTime(2026, 10, 15, 14, 30); // A Thursday

    test('Daily period bounds start at 00:00:00 and end at 23:59:59.999', () {
      final (start, end) = BudgetProgress.calculatePeriodBounds('daily', refDate);
      expect(start, equals(DateTime(2026, 10, 15, 0, 0, 0)));
      expect(end, equals(DateTime(2026, 10, 15, 23, 59, 59, 999)));
    });

    test('Weekly period bounds start on Monday and end on Sunday', () {
      final (start, end) = BudgetProgress.calculatePeriodBounds('weekly', refDate);
      // Monday of Oct 15, 2026 is Oct 12
      expect(start, equals(DateTime(2026, 10, 12, 0, 0, 0)));
      // Sunday is Oct 18
      expect(end, equals(DateTime(2026, 10, 18, 23, 59, 59, 999)));
    });

    test('Monthly period bounds span the first to last day of the month', () {
      final (start, end) = BudgetProgress.calculatePeriodBounds('monthly', refDate);
      expect(start, equals(DateTime(2026, 10, 1, 0, 0, 0)));
      expect(end.year, equals(2026));
      expect(end.month, equals(10));
      expect(end.day, equals(31));
    });

    test('Budget computation accurately aggregates expenses and respects category filters', () {
      final budget = BudgetEntry(
        id: 'b1',
        name: 'Food & Dining',
        amountCents: 1000000, // Rs. 10,000.00
        currency: 'LKR',
        periodType: 'monthly',
        startDate: DateTime(2026, 10, 1),
        category: 'Food',
        alertThresholdPercent: 80,
        isPaused: false,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final transactions = [
        // Within period, matching category (expense)
        FinancialTransactionEntry(
          id: 'tx1',
          accountId: 'account_cash',
          type: 'expense',
          amountCents: 300000, // Rs. 3,000
          category: 'Food',
          description: 'Groceries',
          transactionDate: DateTime(2026, 10, 5),
          createdAt: DateTime(2026, 10, 5),
          updatedAt: DateTime(2026, 10, 5),
        ),
        // Within period, matching category (expense)
        FinancialTransactionEntry(
          id: 'tx2',
          accountId: 'account_card',
          type: 'expense',
          amountCents: 400000, // Rs. 4,000
          category: 'food', // test case-insensitivity
          description: 'Dinner',
          transactionDate: DateTime(2026, 10, 10),
          createdAt: DateTime(2026, 10, 10),
          updatedAt: DateTime(2026, 10, 10),
        ),
        // Income in Food category - must NOT count towards expense budget
        FinancialTransactionEntry(
          id: 'tx3',
          accountId: 'account_cash',
          type: 'income',
          amountCents: 500000,
          category: 'Food',
          description: 'Food refund',
          transactionDate: DateTime(2026, 10, 12),
          createdAt: DateTime(2026, 10, 12),
          updatedAt: DateTime(2026, 10, 12),
        ),
        // Expense in different category - must NOT count towards Food budget
        FinancialTransactionEntry(
          id: 'tx4',
          accountId: 'account_cash',
          type: 'expense',
          amountCents: 200000,
          category: 'Transport',
          description: 'Bus ticket',
          transactionDate: DateTime(2026, 10, 14),
          createdAt: DateTime(2026, 10, 14),
          updatedAt: DateTime(2026, 10, 14),
        ),
        // Expense in previous month - must NOT count
        FinancialTransactionEntry(
          id: 'tx5',
          accountId: 'account_cash',
          type: 'expense',
          amountCents: 500000,
          category: 'Food',
          description: 'Old groceries',
          transactionDate: DateTime(2026, 9, 25),
          createdAt: DateTime(2026, 9, 25),
          updatedAt: DateTime(2026, 9, 25),
        ),
      ];

      final progress = BudgetProgress.compute(
        budget: budget,
        transactions: transactions,
        referenceDate: refDate,
      );

      expect(progress.spentCents, equals(700000)); // 3000 + 4000 = Rs. 7,000
      expect(progress.remainingCents, equals(300000)); // 10000 - 7000 = Rs. 3,000
      expect(progress.percentageUsed, closeTo(70.0, 0.01));
      expect(progress.isOverBudget, isFalse);
      expect(progress.hasReachedAlertThreshold, isFalse); // 70% < 80%
    });

    test('Alert threshold and over-budget triggers correctly', () {
      final budget = BudgetEntry(
        id: 'b2',
        name: 'Weekly Allowance',
        amountCents: 500000, // Rs. 5,000
        currency: 'LKR',
        periodType: 'weekly',
        startDate: DateTime(2026, 10, 12),
        category: 'All', // covers all categories
        alertThresholdPercent: 80,
        isPaused: false,
        createdAt: DateTime(2026, 10, 12),
        updatedAt: DateTime(2026, 10, 12),
      );

      // Spent 4200 (84% of 5000)
      final txUnderThreshold = [
        FinancialTransactionEntry(
          id: 'tx1',
          accountId: 'account_cash',
          type: 'expense',
          amountCents: 420000,
          category: 'Shopping',
          description: 'Shoes',
          transactionDate: DateTime(2026, 10, 13),
          createdAt: DateTime(2026, 10, 13),
          updatedAt: DateTime(2026, 10, 13),
        ),
      ];

      final progress1 = BudgetProgress.compute(
        budget: budget,
        transactions: txUnderThreshold,
        referenceDate: refDate,
      );

      expect(progress1.percentageUsed, closeTo(84.0, 0.01));
      expect(progress1.hasReachedAlertThreshold, isTrue); // 84% >= 80%
      expect(progress1.isOverBudget, isFalse);
      expect(progress1.remainingCents, equals(80000));

      // Over budget: spent 5500
      final txOverBudget = [
        ...txUnderThreshold,
        FinancialTransactionEntry(
          id: 'tx2',
          accountId: 'account_cash',
          type: 'expense',
          amountCents: 130000,
          category: 'Transport',
          description: 'Cab',
          transactionDate: DateTime(2026, 10, 14),
          createdAt: DateTime(2026, 10, 14),
          updatedAt: DateTime(2026, 10, 14),
        ),
      ];

      final progress2 = BudgetProgress.compute(
        budget: budget,
        transactions: txOverBudget,
        referenceDate: refDate,
      );

      expect(progress2.spentCents, equals(550000));
      expect(progress2.remainingCents, equals(0)); // clamped to 0
      expect(progress2.isOverBudget, isTrue);
      expect(progress2.hasReachedAlertThreshold, isTrue);
    });
  });

  group('Category Color & Icon Parsing', () {
    test('Parses hex color codes correctly with fallback safety', () {
      final color = parseCategoryColor('#10B981');
      expect(color.toARGB32(), equals(0xFF10B981));

      final fallbackColor = parseCategoryColor('invalid_hex');
      expect(fallbackColor, isNotNull);

      final nullColor = parseCategoryColor(null);
      expect(nullColor, isNotNull);
    });

    test('Maps category icon names safely with fallback', () {
      final icon = getFinanceCategoryIcon('restaurant');
      expect(icon, isNotNull);

      final fallbackIcon = getFinanceCategoryIcon('unknown_icon_name');
      expect(fallbackIcon, isNotNull);

      final nullIcon = getFinanceCategoryIcon(null);
      expect(nullIcon, isNotNull);
    });
  });

  group('Drift Database & FinanceRepository Integration', () {
    late AppDatabase db;
    late DriftFinanceRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftFinanceRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Create, retrieve, pause, and delete multi-period budgets', () async {
      final budgetId = await repo.createBudget(
        name: 'Daily Coffee',
        amountCents: 50000, // Rs. 500
        periodType: 'daily',
        startDate: DateTime(2026, 10, 15),
        category: 'Food',
        alertThresholdPercent: 75,
      );

      final budgets = await repo.getAllBudgets();
      expect(budgets.length, equals(1));
      expect(budgets.first.name, equals('Daily Coffee'));
      expect(budgets.first.amountCents, equals(50000));
      expect(budgets.first.isPaused, isFalse);

      // Toggle pause
      await repo.togglePauseBudget(budgetId);
      final pausedBudgets = await repo.getAllBudgets();
      expect(pausedBudgets.first.isPaused, isTrue);

      // Delete budget
      await repo.deleteBudget(budgetId);
      final remaining = await repo.getAllBudgets();
      expect(remaining, isEmpty);
    });

    test('Create, retrieve, update, and delete custom categories', () async {
      final catId = await repo.createCategory(
        name: 'Gym & Fitness',
        type: 'expense',
        iconName: 'fitness_center',
        colorHex: '#10B981',
      );

      final categories = await repo.getCategories(type: 'expense');
      final gymCat = categories.firstWhere((c) => c.id == catId);
      expect(gymCat.name, equals('Gym & Fitness'));
      expect(gymCat.isCustom, isTrue);

      // Update category
      await repo.updateCategory(
        gymCat.copyWith(name: 'CrossFit Gym'),
      );
      final updatedCats = await repo.getCategories(type: 'expense');
      expect(updatedCats.any((c) => c.name == 'CrossFit Gym'), isTrue);

      // Delete category
      await repo.deleteCategory(catId);
      final finalCats = await repo.getCategories(type: 'expense');
      expect(finalCats.any((c) => c.id == catId), isFalse);
    });
  });
}
