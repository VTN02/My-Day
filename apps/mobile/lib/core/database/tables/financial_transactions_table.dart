import 'package:drift/drift.dart';

/// SQLite schema definition for Financial Transactions.
@DataClassName('FinancialTransactionEntry')
class FinancialTransactionsTable extends Table {
  @override
  String get tableName => 'financial_transactions';

  TextColumn get id => text()();
  TextColumn get accountId => text()(); // References FinancialAccountsTable.id
  TextColumn get type => text()(); // "income", "expense"
  IntColumn get amountCents =>
      integer()(); // Minor units (e.g. 100 LKR = 10000 cents)
  TextColumn get category => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withLength(min: 1, max: 300)();
  DateTimeColumn get transactionDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
