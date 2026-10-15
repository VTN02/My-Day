import 'package:drift/drift.dart';

/// Debt tracking table for Borrowed and Lent money.
@DataClassName('MoneyDebtEntry')
class MoneyDebtsTable extends Table {
  @override
  String get tableName => 'money_debts';

  TextColumn get id => text()();
  TextColumn get type => text()(); // 'borrowed' or 'lent'
  TextColumn get personName => text().withLength(min: 1, max: 200)();
  IntColumn get initialAmountCents => integer()();
  IntColumn get remainingAmountCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('LKR'))();
  DateTimeColumn get issueDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get reminderOption =>
      text().withDefault(const Constant('on_due_date'))();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  TextColumn get linkedAccountId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Partial and full repayment logs for MoneyDebts.
@DataClassName('MoneyDebtRepaymentEntry')
class MoneyDebtRepaymentsTable extends Table {
  @override
  String get tableName => 'money_debt_repayments';

  TextColumn get id => text()();
  TextColumn get debtId => text()(); // References MoneyDebtsTable.id
  IntColumn get amountCents => integer()();
  DateTimeColumn get repaymentDate => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get linkedAccountId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
