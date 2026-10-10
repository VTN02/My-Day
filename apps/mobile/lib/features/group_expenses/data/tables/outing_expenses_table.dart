import 'package:drift/drift.dart';

/// SQLite schema definition for Outing Expenses.
@DataClassName('OutingExpenseEntry')
class OutingExpensesTable extends Table {
  @override
  String get tableName => 'outing_expenses';

  TextColumn get id => text()(); // UUID v4
  TextColumn get outingId => text()(); // References GroupOutingsTable.id
  TextColumn get payerMemberId => text()(); // References OutingMembersTable.id
  TextColumn get title => text().withLength(min: 1, max: 150)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text().withLength(
    min: 1,
    max: 50,
  )(); // 'food', 'transport', 'tickets', etc.
  IntColumn get amountMinor =>
      integer()(); // Minor units (e.g., 6000 LKR = 600000 cents)
  DateTimeColumn get expenseDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
