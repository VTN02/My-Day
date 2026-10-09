import 'package:drift/drift.dart';

/// SQLite schema definition for User Profile.
@DataClassName('UserProfileEntry')
class UserProfileTable extends Table {
  @override
  String get tableName => 'user_profile';

  TextColumn get id => text()(); // "me"
  TextColumn get displayName => text().withLength(min: 1, max: 150)();
  TextColumn get bio => text().nullable()();
  TextColumn get organization => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get preferredLanguage =>
      text().withDefault(const Constant('en'))();
  TextColumn get preferredCurrency =>
      text().withDefault(const Constant('LKR'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite schema definition for App Settings key-value pairs.
@DataClassName('AppSettingEntry')
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
