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

/// Unified multi-period spending budgets table (Daily, Weekly, Monthly)
@DataClassName('BudgetEntry')
class BudgetsTable extends Table {
  @override
  String get tableName => 'budgets';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('LKR'))();
  TextColumn get periodType => text()(); // 'daily', 'weekly', 'monthly'
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get category => text().nullable()(); // null or 'All' or specific category name
  IntColumn get alertThresholdPercent =>
      integer().withDefault(const Constant(80))();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
