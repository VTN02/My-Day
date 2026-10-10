import 'package:drift/drift.dart';

/// SQLite schema definition for Outing Settlements / Repayments.
@DataClassName('OutingSettlementEntry')
class OutingSettlementsTable extends Table {
  @override
  String get tableName => 'outing_settlements';

  TextColumn get id => text()(); // UUID v4
  TextColumn get outingId => text()(); // References GroupOutingsTable.id
  TextColumn get fromMemberId => text()(); // Debtor (who paid back)
  TextColumn get toMemberId => text()(); // Creditor (who received money)
  IntColumn get amountMinor =>
      integer()(); // Repayment amount in minor units (cents)
  DateTimeColumn get settlementDate => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get paymentMethod => text().withDefault(
    const Constant('cash'),
  )(); // 'cash', 'bank_transfer', etc.
  TextColumn get status => text().withDefault(
    const Constant('completed'),
  )(); // 'completed', 'reversed'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
