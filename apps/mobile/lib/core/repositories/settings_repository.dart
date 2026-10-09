import '../database/app_database.dart';

abstract class SettingsRepository {
  Stream<String?> watchSetting(String key);
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
}

class DriftSettingsRepository implements SettingsRepository {
  final AppDatabase _db;

  DriftSettingsRepository(this._db);

  @override
  Stream<String?> watchSetting(String key) {
    return (_db.select(_db.appSettingsTable)..where((s) => s.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  @override
  Future<String?> getSetting(String key) async {
    final entry = await (_db.select(
      _db.appSettingsTable,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return entry?.value;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    await _db
        .into(_db.appSettingsTable)
        .insertOnConflictUpdate(
          AppSettingsTableCompanion.insert(key: key, value: value),
        );
  }
}
