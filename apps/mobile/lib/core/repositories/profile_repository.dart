import 'package:drift/drift.dart';
import '../database/app_database.dart';

abstract class ProfileRepository {
  Stream<UserProfileEntry?> watchProfile();
  Future<UserProfileEntry?> getProfile();
  Future<void> updateProfile({
    required String displayName,
    String? bio,
    String? organization,
    String? avatarPath,
    String? preferredLanguage,
    String? preferredCurrency,
  });
}

class DriftProfileRepository implements ProfileRepository {
  final AppDatabase _db;

  DriftProfileRepository(this._db);

  @override
  Stream<UserProfileEntry?> watchProfile() {
    return (_db.select(
      _db.userProfileTable,
    )..where((u) => u.id.equals('me'))).watchSingleOrNull();
  }

  @override
  Future<UserProfileEntry?> getProfile() {
    return (_db.select(
      _db.userProfileTable,
    )..where((u) => u.id.equals('me'))).getSingleOrNull();
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    String? bio,
    String? organization,
    String? avatarPath,
    String? preferredLanguage,
    String? preferredCurrency,
  }) async {
    await (_db.into(_db.userProfileTable)).insertOnConflictUpdate(
      UserProfileTableCompanion.insert(
        id: 'me',
        displayName: displayName,
        bio: Value(bio),
        organization: Value(organization),
        avatarPath: Value(avatarPath),
        preferredLanguage: Value(preferredLanguage ?? 'en'),
        preferredCurrency: Value(preferredCurrency ?? 'LKR'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
