import 'package:drift/drift.dart';

/// Predefined and user-custom income/expense categories.
@DataClassName('FinanceCategoryEntry')
class FinanceCategoriesTable extends Table {
  @override
  String get tableName => 'finance_categories';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'expense' or 'income'
  TextColumn get iconName => text().withDefault(const Constant('category'))();
  TextColumn get colorHex => text().withDefault(const Constant('#4F46E5'))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
