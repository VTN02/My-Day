import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

abstract class MoneyTrackerRepository {
  Stream<List<MoneyDebtEntry>> watchAllDebts();
  Stream<List<MoneyDebtEntry>> watchDebtsByType(String type); // 'lent' or 'borrowed'
  Future<List<MoneyDebtEntry>> getAllDebts();
  Future<MoneyDebtEntry?> getDebt(String id);

  Future<String> createDebt({
    required String type, // 'lent' or 'borrowed'
    required String personName,
    required int initialAmountCents,
    String currency = 'LKR',
    required DateTime issueDate,
    DateTime? dueDate,
    String? description,
    bool reminderEnabled = true,
    String reminderOption = 'on_due_date',
    String? linkedAccountId,
    bool updateAccountBalance = false,
  });

  Future<String> recordRepayment({
    required String debtId,
    required int amountCents,
    required DateTime repaymentDate,
    String? notes,
    String? linkedAccountId,
    bool updateAccountBalance = false,
  });

  Stream<List<MoneyDebtRepaymentEntry>> watchRepayments(String debtId);
  Future<List<MoneyDebtRepaymentEntry>> getRepayments(String debtId);
  Future<void> updateDebt(MoneyDebtEntry debt);
  Future<void> deleteDebt(String id);
}

class DriftMoneyTrackerRepository implements MoneyTrackerRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  DriftMoneyTrackerRepository(this._db);

  @override
  Stream<List<MoneyDebtEntry>> watchAllDebts() {
    final query = _db.select(_db.moneyDebtsTable)
      ..orderBy([
        (d) => OrderingTerm(expression: d.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  @override
  Stream<List<MoneyDebtEntry>> watchDebtsByType(String type) {
    final query = _db.select(_db.moneyDebtsTable)
      ..where((d) => d.type.equals(type.toLowerCase()))
      ..orderBy([
        (d) => OrderingTerm(expression: d.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  @override
  Future<List<MoneyDebtEntry>> getAllDebts() {
    return _db.select(_db.moneyDebtsTable).get();
  }

  @override
  Future<MoneyDebtEntry?> getDebt(String id) {
    return (_db.select(_db.moneyDebtsTable)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<String> createDebt({
    required String type,
    required String personName,
    required int initialAmountCents,
    String currency = 'LKR',
    required DateTime issueDate,
    DateTime? dueDate,
    String? description,
    bool reminderEnabled = true,
    String reminderOption = 'on_due_date',
    String? linkedAccountId,
    bool updateAccountBalance = false,
  }) async {
    final debtId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.moneyDebtsTable).insert(
            MoneyDebtsTableCompanion.insert(
              id: debtId,
              type: type.toLowerCase(),
              personName: personName,
              initialAmountCents: initialAmountCents,
              remainingAmountCents: initialAmountCents,
              currency: Value(currency),
              issueDate: issueDate,
              dueDate: Value(dueDate),
              description: Value(description),
              reminderEnabled: Value(reminderEnabled),
              reminderOption: Value(reminderOption),
              status: const Value('unpaid'),
              linkedAccountId: Value(linkedAccountId),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      // If requested, sync transaction to update liquid account balance
      if (updateAccountBalance && linkedAccountId != null) {
        final isLent = type.toLowerCase() == 'lent';
        final txType = isLent ? 'expense' : 'income';
        final txDesc = isLent
            ? 'Lent to $personName${description != null ? " ($description)" : ""}'
            : 'Borrowed from $personName${description != null ? " ($description)" : ""}'
                .trim();

        final txId = _uuid.v4();
        await _db.into(_db.financialTransactionsTable).insert(
              FinancialTransactionsTableCompanion.insert(
                id: txId,
                accountId: linkedAccountId,
                type: txType,
                amountCents: initialAmountCents,
                category: 'Other',
                description: txDesc,
                transactionDate: issueDate,
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        // Adjust account currentBalance
        final account = await (_db.select(_db.financialAccountsTable)
              ..where((a) => a.id.equals(linkedAccountId)))
            .getSingleOrNull();
        if (account != null) {
          final newBal = isLent
              ? account.currentBalanceCents - initialAmountCents
              : account.currentBalanceCents + initialAmountCents;
          await (_db.update(_db.financialAccountsTable)
                ..where((a) => a.id.equals(linkedAccountId)))
              .write(
            FinancialAccountsTableCompanion(
              currentBalanceCents: Value(newBal),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });

    return debtId;
  }

  @override
  Future<String> recordRepayment({
    required String debtId,
    required int amountCents,
    required DateTime repaymentDate,
    String? notes,
    String? linkedAccountId,
    bool updateAccountBalance = false,
  }) async {
    final repaymentId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      final debt = await getDebt(debtId);
      if (debt == null) throw Exception('Debt not found: $debtId');

      final newRemaining = (debt.remainingAmountCents - amountCents).clamp(0, debt.initialAmountCents);
      final newStatus = newRemaining == 0 ? 'settled' : 'partially_paid';

      // Insert repayment log
      await _db.into(_db.moneyDebtRepaymentsTable).insert(
            MoneyDebtRepaymentsTableCompanion.insert(
              id: repaymentId,
              debtId: debtId,
              amountCents: amountCents,
              repaymentDate: repaymentDate,
              notes: Value(notes),
              linkedAccountId: Value(linkedAccountId),
              createdAt: Value(now),
            ),
          );

      // Update remaining balance & status on debt
      await (_db.update(_db.moneyDebtsTable)..where((d) => d.id.equals(debtId)))
          .write(
        MoneyDebtsTableCompanion(
          remainingAmountCents: Value(newRemaining),
          status: Value(newStatus),
          updatedAt: Value(now),
        ),
      );

      // If requested, sync transaction to update liquid account balance
      if (updateAccountBalance && linkedAccountId != null) {
        final isLent = debt.type.toLowerCase() == 'lent';
        // If lent money is repaid: cash comes in (income)
        // If borrowed money is repaid: cash goes out (expense)
        final txType = isLent ? 'income' : 'expense';
        final txDesc = isLent
            ? 'Repayment received from ${debt.personName}${notes != null ? " ($notes)" : ""}'
            : 'Repaid ${debt.personName}${notes != null ? " ($notes)" : ""}'
                .trim();

        final txId = _uuid.v4();
        await _db.into(_db.financialTransactionsTable).insert(
              FinancialTransactionsTableCompanion.insert(
                id: txId,
                accountId: linkedAccountId,
                type: txType,
                amountCents: amountCents,
                category: 'Other',
                description: txDesc,
                transactionDate: repaymentDate,
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        // Adjust account currentBalance
        final account = await (_db.select(_db.financialAccountsTable)
              ..where((a) => a.id.equals(linkedAccountId)))
            .getSingleOrNull();
        if (account != null) {
          final newBal = isLent
              ? account.currentBalanceCents + amountCents
              : account.currentBalanceCents - amountCents;
          await (_db.update(_db.financialAccountsTable)
                ..where((a) => a.id.equals(linkedAccountId)))
              .write(
            FinancialAccountsTableCompanion(
              currentBalanceCents: Value(newBal),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });

    return repaymentId;
  }

  @override
  Stream<List<MoneyDebtRepaymentEntry>> watchRepayments(String debtId) {
    final query = _db.select(_db.moneyDebtRepaymentsTable)
      ..where((r) => r.debtId.equals(debtId))
      ..orderBy([
        (r) => OrderingTerm(expression: r.repaymentDate, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  @override
  Future<List<MoneyDebtRepaymentEntry>> getRepayments(String debtId) {
    final query = _db.select(_db.moneyDebtRepaymentsTable)
      ..where((r) => r.debtId.equals(debtId))
      ..orderBy([
        (r) => OrderingTerm(expression: r.repaymentDate, mode: OrderingMode.desc),
      ]);
    return query.get();
  }

  @override
  Future<void> updateDebt(MoneyDebtEntry debt) async {
    await (_db.update(_db.moneyDebtsTable)..where((d) => d.id.equals(debt.id)))
        .write(
      MoneyDebtsTableCompanion(
        personName: Value(debt.personName),
        dueDate: Value(debt.dueDate),
        description: Value(debt.description),
        reminderEnabled: Value(debt.reminderEnabled),
        reminderOption: Value(debt.reminderOption),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.moneyDebtRepaymentsTable)
            ..where((r) => r.debtId.equals(id)))
          .go();
      await (_db.delete(_db.moneyDebtsTable)..where((d) => d.id.equals(id))).go();
    });
  }
}
