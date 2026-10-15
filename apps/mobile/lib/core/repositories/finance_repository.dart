import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

abstract class FinanceRepository {
  Stream<List<FinancialAccountEntry>> watchAccounts();
  Future<FinancialAccountEntry?> getAccount(String id);
  Future<void> setOpeningBalance(String accountId, int openingBalanceCents);

  Stream<List<FinancialTransactionEntry>> watchAllTransactions();
  Stream<List<FinancialTransactionEntry>> watchRecentTransactions({
    int limit = 10,
  });
  Stream<List<FinancialTransactionEntry>> watchTransactionsForMonth(
    int year,
    int month,
  );

  Future<String> recordTransaction({
    required String accountId,
    required String type, // 'income' or 'expense'
    required int amountCents,
    required String category,
    required String description,
    required DateTime transactionDate,
  });

  Future<void> deleteTransaction(String id);

  Stream<MonthlyBudgetEntry?> watchBudgetForMonth(int year, int month);
  Future<void> setMonthlyBudget(int year, int month, int totalBudgetCents);

  // Multi-period Budgets (Daily, Weekly, Monthly)
  Stream<List<BudgetEntry>> watchBudgets();
  Future<List<BudgetEntry>> getAllBudgets();
  Future<String> createBudget({
    required String name,
    required int amountCents,
    String currency = 'LKR',
    required String periodType, // 'daily', 'weekly', 'monthly'
    required DateTime startDate,
    DateTime? endDate,
    String? category,
    int alertThresholdPercent = 80,
  });
  Future<void> updateBudget(BudgetEntry budget);
  Future<void> deleteBudget(String id);
  Future<void> togglePauseBudget(String id);

  // Categories (Predefined & Custom)
  Stream<List<FinanceCategoryEntry>> watchCategories({String? type});
  Future<List<FinanceCategoryEntry>> getCategories({String? type});
  Future<String> createCategory({
    required String name,
    required String type, // 'expense' or 'income'
    String iconName = 'category',
    String colorHex = '#4F46E5',
    bool isCustom = true,
  });
  Future<void> updateCategory(FinanceCategoryEntry category);
  Future<void> deleteCategory(String id);
}

class DriftFinanceRepository implements FinanceRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  DriftFinanceRepository(this._db);

  @override
  Stream<List<FinancialAccountEntry>> watchAccounts() {
    return _db.select(_db.financialAccountsTable).watch();
  }

  @override
  Future<FinancialAccountEntry?> getAccount(String id) {
    return (_db.select(
      _db.financialAccountsTable,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<void> setOpeningBalance(
    String accountId,
    int openingBalanceCents,
  ) async {
    await _db.transaction(() async {
      final account = await getAccount(accountId);
      if (account == null) return;

      // Recalculate current balance = openingBalance + sum(incomes) - sum(expenses)
      final transactions = await (_db.select(
        _db.financialTransactionsTable,
      )..where((t) => t.accountId.equals(accountId))).get();

      var netChange = 0;
      for (final tx in transactions) {
        if (tx.type == 'income') {
          netChange += tx.amountCents;
        } else {
          netChange -= tx.amountCents;
        }
      }

      final newCurrentBalance = openingBalanceCents + netChange;

      await (_db.update(
        _db.financialAccountsTable,
      )..where((a) => a.id.equals(accountId))).write(
        FinancialAccountsTableCompanion(
          openingBalanceCents: Value(openingBalanceCents),
          currentBalanceCents: Value(newCurrentBalance),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Stream<List<FinancialTransactionEntry>> watchAllTransactions() {
    final query = _db.select(_db.financialTransactionsTable)
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.transactionDate,
          mode: OrderingMode.desc,
        ),
      ]);
    return query.watch();
  }

  @override
  Stream<List<FinancialTransactionEntry>> watchRecentTransactions({
    int limit = 10,
  }) {
    final query = _db.select(_db.financialTransactionsTable)
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.transactionDate,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    return query.watch();
  }

  @override
  Stream<List<FinancialTransactionEntry>> watchTransactionsForMonth(
    int year,
    int month,
  ) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59, 999);

    final query = _db.select(_db.financialTransactionsTable)
      ..where(
        (t) =>
            t.transactionDate.isBiggerOrEqualValue(startOfMonth) &
            t.transactionDate.isSmallerOrEqualValue(endOfMonth),
      )
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.transactionDate,
          mode: OrderingMode.desc,
        ),
      ]);
    return query.watch();
  }

  @override
  Future<String> recordTransaction({
    required String accountId,
    required String type,
    required int amountCents,
    required String category,
    required String description,
    required DateTime transactionDate,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      // 1. Insert transaction
      await _db
          .into(_db.financialTransactionsTable)
          .insert(
            FinancialTransactionsTableCompanion.insert(
              id: id,
              accountId: accountId,
              type: type,
              amountCents: amountCents,
              category: category,
              description: description,
              transactionDate: transactionDate,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      // 2. Adjust account current balance
      final account = await getAccount(accountId);
      if (account != null) {
        final balanceAdjustment = type == 'income' ? amountCents : -amountCents;
        final newBalance = account.currentBalanceCents + balanceAdjustment;

        await (_db.update(
          _db.financialAccountsTable,
        )..where((a) => a.id.equals(accountId))).write(
          FinancialAccountsTableCompanion(
            currentBalanceCents: Value(newBalance),
            updatedAt: Value(now),
          ),
        );
      }
    });

    return id;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _db.transaction(() async {
      final tx = await (_db.select(
        _db.financialTransactionsTable,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (tx == null) return;

      // Revert account current balance
      final account = await getAccount(tx.accountId);
      if (account != null) {
        final reverseAdjustment = tx.type == 'income'
            ? -tx.amountCents
            : tx.amountCents;
        final newBalance = account.currentBalanceCents + reverseAdjustment;

        await (_db.update(
          _db.financialAccountsTable,
        )..where((a) => a.id.equals(tx.accountId))).write(
          FinancialAccountsTableCompanion(
            currentBalanceCents: Value(newBalance),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      // Delete transaction
      await (_db.delete(
        _db.financialTransactionsTable,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Stream<MonthlyBudgetEntry?> watchBudgetForMonth(int year, int month) {
    return (_db.select(_db.monthlyBudgetsTable)
          ..where((b) => b.year.equals(year) & b.month.equals(month)))
        .watchSingleOrNull();
  }

  @override
  Future<void> setMonthlyBudget(
    int year,
    int month,
    int totalBudgetCents,
  ) async {
    final existing =
        await (_db.select(_db.monthlyBudgetsTable)
              ..where((b) => b.year.equals(year) & b.month.equals(month)))
            .getSingleOrNull();

    final now = DateTime.now();
    if (existing != null) {
      await (_db.update(
        _db.monthlyBudgetsTable,
      )..where((b) => b.id.equals(existing.id))).write(
        MonthlyBudgetsTableCompanion(
          totalBudgetCents: Value(totalBudgetCents),
          updatedAt: Value(now),
        ),
      );
    } else {
      await _db
          .into(_db.monthlyBudgetsTable)
          .insert(
            MonthlyBudgetsTableCompanion.insert(
              id: _uuid.v4(),
              year: year,
              month: month,
              totalBudgetCents: totalBudgetCents,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
  }

  @override
  Stream<List<BudgetEntry>> watchBudgets() {
    final query = _db.select(_db.budgetsTable)
      ..orderBy([
        (b) => OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  @override
  Future<List<BudgetEntry>> getAllBudgets() {
    return (_db.select(_db.budgetsTable)
          ..orderBy([
            (b) => OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  @override
  Future<String> createBudget({
    required String name,
    required int amountCents,
    String currency = 'LKR',
    required String periodType,
    required DateTime startDate,
    DateTime? endDate,
    String? category,
    int alertThresholdPercent = 80,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.into(_db.budgetsTable).insert(
      BudgetsTableCompanion.insert(
        id: id,
        name: name,
        amountCents: amountCents,
        currency: Value(currency),
        periodType: periodType,
        startDate: startDate,
        endDate: Value(endDate),
        category: Value(category),
        alertThresholdPercent: Value(alertThresholdPercent),
        isPaused: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  @override
  Future<void> updateBudget(BudgetEntry budget) async {
    await (_db.update(_db.budgetsTable)..where((b) => b.id.equals(budget.id)))
        .write(
      BudgetsTableCompanion(
        name: Value(budget.name),
        amountCents: Value(budget.amountCents),
        currency: Value(budget.currency),
        periodType: Value(budget.periodType),
        startDate: Value(budget.startDate),
        endDate: Value(budget.endDate),
        category: Value(budget.category),
        alertThresholdPercent: Value(budget.alertThresholdPercent),
        isPaused: Value(budget.isPaused),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteBudget(String id) async {
    await (_db.delete(_db.budgetsTable)..where((b) => b.id.equals(id))).go();
  }

  @override
  Future<void> togglePauseBudget(String id) async {
    final budget = await (_db.select(_db.budgetsTable)
          ..where((b) => b.id.equals(id)))
        .getSingleOrNull();
    if (budget == null) return;

    await (_db.update(_db.budgetsTable)..where((b) => b.id.equals(id))).write(
      BudgetsTableCompanion(
        isPaused: Value(!budget.isPaused),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Stream<List<FinanceCategoryEntry>> watchCategories({String? type}) {
    final query = _db.select(_db.financeCategoriesTable);
    if (type != null) {
      query.where((c) => c.type.equals(type));
    }
    query.orderBy([
      (c) => OrderingTerm(expression: c.isCustom, mode: OrderingMode.asc),
      (c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc),
    ]);
    return query.watch();
  }

  @override
  Future<List<FinanceCategoryEntry>> getCategories({String? type}) {
    final query = _db.select(_db.financeCategoriesTable);
    if (type != null) {
      query.where((c) => c.type.equals(type));
    }
    query.orderBy([
      (c) => OrderingTerm(expression: c.isCustom, mode: OrderingMode.asc),
      (c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc),
    ]);
    return query.get();
  }

  @override
  Future<String> createCategory({
    required String name,
    required String type,
    String iconName = 'category',
    String colorHex = '#4F46E5',
    bool isCustom = true,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.financeCategoriesTable).insert(
      FinanceCategoriesTableCompanion.insert(
        id: id,
        name: name,
        type: type,
        iconName: Value(iconName),
        colorHex: Value(colorHex),
        isCustom: Value(isCustom),
        createdAt: Value(DateTime.now()),
      ),
    );
    return id;
  }

  @override
  Future<void> updateCategory(FinanceCategoryEntry category) async {
    await (_db.update(_db.financeCategoriesTable)
          ..where((c) => c.id.equals(category.id)))
        .write(
      FinanceCategoriesTableCompanion(
        name: Value(category.name),
        iconName: Value(category.iconName),
        colorHex: Value(category.colorHex),
      ),
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    await (_db.delete(_db.financeCategoriesTable)..where((c) => c.id.equals(id)))
        .go();
  }
}
