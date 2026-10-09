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
}
