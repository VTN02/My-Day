import 'package:drift/drift.dart';

/// SQLite schema definition for Monthly Budgets.
@DataClassName('MonthlyBudgetEntry')
class MonthlyBudgetsTable extends Table {
  @override
  String get tableName => 'monthly_budgets';

  TextColumn get id => text()();
  IntColumn get year => integer()();
  IntColumn get month => integer()(); // 1-12
  IntColumn get totalBudgetCents => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Category budget allocations under a monthly budget.
@DataClassName('BudgetAllocationEntry')
class BudgetAllocationsTable extends Table {
  @override
  String get tableName => 'budget_allocations';

  TextColumn get id => text()();
  TextColumn get budgetId => text()(); // References MonthlyBudgetsTable.id
  TextColumn get category => text()();
  IntColumn get allocatedCents => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
