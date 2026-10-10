import 'package:drift/drift.dart';

/// SQLite schema definition for Outing Expense Shares.
@DataClassName('OutingExpenseShareEntry')
class OutingExpenseSharesTable extends Table {
  @override
  String get tableName => 'outing_expense_shares';

  TextColumn get id => text()(); // UUID v4
  TextColumn get expenseId => text()(); // References OutingExpensesTable.id
  TextColumn get memberId => text()(); // References OutingMembersTable.id
  IntColumn get amountMinor =>
      integer()(); // Member's share in minor units (cents)

  @override
  Set<Column> get primaryKey => {id};
}
