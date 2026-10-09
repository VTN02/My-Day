import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_providers.dart';

/// Service responsible for exporting and restoring full SQLite offline data as JSON.
class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Exports all tables to a structured JSON string.
  Future<String> exportBackupJson() async {
    final profile = await _db.select(_db.userProfileTable).getSingleOrNull();
    final tasks = await _db.select(_db.tasksTable).get();
    final categories = await _db.select(_db.taskCategoriesTable).get();
    final accounts = await _db.select(_db.financialAccountsTable).get();
    final transactions = await _db.select(_db.financialTransactionsTable).get();
    final budgets = await _db.select(_db.monthlyBudgetsTable).get();
    final notes = await _db.select(_db.notesTable).get();
    final attachments = await _db.select(_db.noteAttachmentsTable).get();
    final settings = await _db.select(_db.appSettingsTable).get();
    final habits = await _db.select(_db.habitsTable).get();
    final habitLogs = await _db.select(_db.habitLogsTable).get();

    final payload = {
      'app': 'MyDay',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'summary': {
        'tasksCount': tasks.length,
        'accountsCount': accounts.length,
        'transactionsCount': transactions.length,
        'budgetsCount': budgets.length,
        'notesCount': notes.length,
        'attachmentsCount': attachments.length,
        'habitsCount': habits.length,
        'habitLogsCount': habitLogs.length,
      },
      'data': {
        'userProfile': profile?.toJson(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'taskCategories': categories.map((c) => c.toJson()).toList(),
        'financialAccounts': accounts.map((a) => a.toJson()).toList(),
        'financialTransactions': transactions.map((t) => t.toJson()).toList(),
        'monthlyBudgets': budgets.map((b) => b.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
        'noteAttachments': attachments.map((a) => a.toJson()).toList(),
        'appSettings': settings.map((s) => s.toJson()).toList(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'habitLogs': habitLogs.map((l) => l.toJson()).toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Restores data from a backup JSON string with atomic transaction safety.
  Future<Map<String, int>> restoreBackupJson(String jsonString) async {
    final decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic> || decoded['app'] != 'MyDay') {
      throw const FormatException('Invalid MyDay backup format.');
    }

    final data = decoded['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('No data payload found in backup file.');
    }

    var restoredTasks = 0;
    var restoredNotes = 0;
    var restoredTransactions = 0;

    await _db.transaction(() async {
      // 1. Restore User Profile
      if (data['userProfile'] != null) {
        final profileMap = Map<String, dynamic>.from(
          data['userProfile'] as Map,
        );
        final profile = UserProfileEntry.fromJson(profileMap);
        await _db.into(_db.userProfileTable).insertOnConflictUpdate(profile);
      }

      // 2. Restore Financial Accounts
      if (data['financialAccounts'] is List) {
        for (final item in data['financialAccounts'] as List) {
          final account = FinancialAccountEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          await _db
              .into(_db.financialAccountsTable)
              .insertOnConflictUpdate(account);
        }
      }

      // 3. Restore Financial Transactions
      if (data['financialTransactions'] is List) {
        for (final item in data['financialTransactions'] as List) {
          final tx = FinancialTransactionEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          await _db
              .into(_db.financialTransactionsTable)
              .insertOnConflictUpdate(tx);
          restoredTransactions++;
        }
      }

      // 4. Restore Monthly Budgets
      if (data['monthlyBudgets'] is List) {
        for (final item in data['monthlyBudgets'] as List) {
          final budget = MonthlyBudgetEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          await _db
              .into(_db.monthlyBudgetsTable)
              .insertOnConflictUpdate(budget);
        }
      }

      // 5. Restore Tasks
      if (data['tasks'] is List) {
        for (final item in data['tasks'] as List) {
          final task = TaskEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          await _db.into(_db.tasksTable).insertOnConflictUpdate(task);
          restoredTasks++;
        }
      }

      // 6. Restore Notes
      if (data['notes'] is List) {
        for (final item in data['notes'] as List) {
          final note = NoteEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          await _db.into(_db.notesTable).insertOnConflictUpdate(note);
          restoredNotes++;
        }
      }

      // 7. Restore Note Attachments
      if (data['noteAttachments'] is List) {
        for (final item in data['noteAttachments'] as List) {
          final att = NoteAttachmentEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          await _db.into(_db.noteAttachmentsTable).insertOnConflictUpdate(att);
        }
      }

      // 8. Restore App Settings
      if (data['appSettings'] is List) {
        for (final item in data['appSettings'] as List) {
          final setting = AppSettingEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          await _db.into(_db.appSettingsTable).insertOnConflictUpdate(setting);
        }
      }

      // 9. Restore Habits
      if (data['habits'] is List) {
        for (final item in data['habits'] as List) {
          final habit = HabitEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          await _db.into(_db.habitsTable).insertOnConflictUpdate(habit);
        }
      }

      // 10. Restore Habit Logs
      if (data['habitLogs'] is List) {
        for (final item in data['habitLogs'] as List) {
          final log = HabitLogEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          await _db.into(_db.habitLogsTable).insertOnConflictUpdate(log);
        }
      }
    });

    return {
      'tasks': restoredTasks,
      'notes': restoredNotes,
      'transactions': restoredTransactions,
    };
  }
}

/// Riverpod provider for BackupService
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});
