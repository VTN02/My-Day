import 'package:drift/drift.dart';

/// SQLite schema definition for Financial Accounts (Cash & Card).
@DataClassName('FinancialAccountEntry')
class FinancialAccountsTable extends Table {
  @override
  String get tableName => 'financial_accounts';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // "cash", "card"
  IntColumn get openingBalanceCents => integer().withDefault(const Constant(0))();
  IntColumn get currentBalanceCents => integer().withDefault(const Constant(0))();
  TextColumn get currencyCode => text().withDefault(const Constant('LKR'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
