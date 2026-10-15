import 'package:drift/drift.dart';
import 'connection/connection.dart';
import 'tables/budgets_table.dart';
import 'tables/financial_accounts_table.dart';
import 'tables/financial_transactions_table.dart';
import 'tables/habits_table.dart';
import 'tables/note_folders_table.dart';
import 'tables/notes_table.dart';
import 'tables/scheduled_reminders_table.dart';
import 'tables/task_categories_table.dart';
import 'tables/tasks_table.dart';
import 'tables/user_profile_table.dart';
import 'tables/finance_categories_table.dart';
import 'tables/money_debts_table.dart';
import '../../features/group_expenses/data/tables/group_outings_table.dart';
import '../../features/group_expenses/data/tables/outing_members_table.dart';
import '../../features/group_expenses/data/tables/outing_expenses_table.dart';
import '../../features/group_expenses/data/tables/outing_expense_shares_table.dart';
import '../../features/group_expenses/data/tables/outing_settlements_table.dart';

part 'app_database.g.dart';

/// Central Drift Database for MyDay offline persistence.
@DriftDatabase(
  tables: [
    TasksTable,
    TaskCategoriesTable,
    FinancialAccountsTable,
    FinancialTransactionsTable,
    MonthlyBudgetsTable,
    BudgetAllocationsTable,
    BudgetsTable,
    FinanceCategoriesTable,
    MoneyDebtsTable,
    MoneyDebtRepaymentsTable,
    NoteFoldersTable,
    NotesTable,
    NoteAttachmentsTable,
    UserProfileTable,
    AppSettingsTable,
    HabitsTable,
    HabitLogsTable,
    ScheduledRemindersTable,
    GroupOutingsTable,
    OutingMembersTable,
    OutingExpensesTable,
    OutingExpenseSharesTable,
    OutingSettlementsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedInitialData();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(groupOutingsTable);
        await m.createTable(outingMembersTable);
        await m.createTable(outingExpensesTable);
        await m.createTable(outingExpenseSharesTable);
        await m.createTable(outingSettlementsTable);
      }
      if (from < 3) {
        await m.createTable(noteFoldersTable);
        await m.createTable(scheduledRemindersTable);
        await m.addColumn(notesTable, notesTable.folderId);
        await m.addColumn(notesTable, notesTable.isTrashed);
        await m.addColumn(notesTable, notesTable.trashedAt);
        await m.addColumn(notesTable, notesTable.templateType);
        await m.addColumn(notesTable, notesTable.contentBlocksJson);
        await m.addColumn(notesTable, notesTable.drawingStrokesJson);
        await m.addColumn(tasksTable, tasksTable.followUpEnabled);
        await m.addColumn(tasksTable, tasksTable.followUpDelayMinutes);
        await m.addColumn(tasksTable, tasksTable.maxRepeats);
        await m.addColumn(tasksTable, tasksTable.selectedTuneId);
      }
      if (from < 4) {
        await m.addColumn(tasksTable, tasksTable.completedAt);
      }
      if (from < 5) {
        await m.createTable(budgetsTable);
        await m.createTable(financeCategoriesTable);
        await m.createTable(moneyDebtsTable);
        await m.createTable(moneyDebtRepaymentsTable);
        await _seedFinanceCategories();
      }
    },
  );

  Future<void> _seedInitialData() async {
    final now = DateTime.now();

    // 1. Seed Financial Accounts (Cash and Card)
    await into(financialAccountsTable).insert(
      FinancialAccountsTableCompanion.insert(
        id: 'account_cash',
        name: 'Cash',
        type: 'cash',
        openingBalanceCents: const Value(0),
        currentBalanceCents: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    await into(financialAccountsTable).insert(
      FinancialAccountsTableCompanion.insert(
        id: 'account_card',
        name: 'Card',
        type: 'card',
        openingBalanceCents: const Value(0),
        currentBalanceCents: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    // 2. Seed Default User Profile
    await into(userProfileTable).insert(
      UserProfileTableCompanion.insert(
        id: 'me',
        displayName: 'MyDay User',
        bio: const Value('Building better habits, one day at a time.'),
        preferredLanguage: const Value('en'),
        preferredCurrency: const Value('LKR'),
        updatedAt: Value(now),
      ),
    );

    // 3. Seed Default Task Categories
    final defaultCategories = [
      ('cat_work', 'Work', '#4F46E5', 'work'),
      ('cat_personal', 'Personal', '#10B981', 'person'),
      ('cat_study', 'Study', '#7C3AED', 'school'),
      ('cat_health', 'Health', '#06B6D4', 'favorite'),
    ];

    for (final cat in defaultCategories) {
      await into(taskCategoriesTable).insert(
        TaskCategoriesTableCompanion.insert(
          id: cat.$1,
          name: cat.$2,
          colorHex: Value(cat.$3),
          iconName: Value(cat.$4),
          createdAt: Value(now),
        ),
      );
    }

    // 4. Seed Default Note Folders
    final defaultFolders = [
      ('folder_quick', 'Quick Notes', '#1565C0'),
      ('folder_personal', 'Personal', '#10B981'),
      ('folder_work', 'Work', '#7C3AED'),
      ('folder_ideas', 'Ideas & Projects', '#F59E0B'),
    ];

    for (final f in defaultFolders) {
      await into(noteFoldersTable).insert(
        NoteFoldersTableCompanion.insert(
          id: f.$1,
          name: f.$2,
          colorHex: Value(f.$3),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }

    // 5. Seed Default Habits
    final defaultHabits = [
      (
        'habit_1',
        'Morning Stretch & Mobility',
        'Health',
        'indigo',
        '10 mins of gentle stretching and breathing',
      ),
      (
        'habit_2',
        'Drink 2L Water',
        'Health',
        'teal',
        'Track daily hydration intake',
      ),
      (
        'habit_3',
        'Read 15 Pages',
        'Personal',
        'violet',
        'Read a non-fiction or educational book',
      ),
    ];

    for (final h in defaultHabits) {
      await into(habitsTable).insert(
        HabitsTableCompanion.insert(
          id: h.$1,
          title: h.$2,
          category: Value(h.$3),
          color: Value(h.$4),
          description: Value(h.$5),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }

    // 6. Seed Default Finance Categories
    await _seedFinanceCategories();
  }

  Future<void> _seedFinanceCategories() async {
    final now = DateTime.now();
    final categories = [
      // Expense categories
      ('fcat_food', 'Food', 'expense', 'restaurant', '#EF4444'),
      ('fcat_travel', 'Travel / Transport', 'expense', 'directions_car', '#F59E0B'),
      ('fcat_education', 'Education / Study', 'expense', 'school', '#8B5CF6'),
      ('fcat_shopping', 'Shopping', 'expense', 'shopping_bag', '#EC4899'),
      ('fcat_bills', 'Bills', 'expense', 'receipt_long', '#6366F1'),
      ('fcat_rent', 'Rent / Accommodation', 'expense', 'home', '#14B8A6'),
      ('fcat_health', 'Health', 'expense', 'local_hospital', '#10B981'),
      ('fcat_entertainment', 'Entertainment', 'expense', 'movie', '#F97316'),
      ('fcat_mobile', 'Mobile / Internet', 'expense', 'wifi', '#06B6D4'),
      ('fcat_family', 'Family', 'expense', 'family_restroom', '#A855F7'),
      ('fcat_personal', 'Personal', 'expense', 'person', '#3B82F6'),
      ('fcat_other_exp', 'Other', 'expense', 'category', '#6B7280'),
      // Income categories
      ('fcat_salary', 'Salary', 'income', 'payments', '#10B981'),
      ('fcat_allowance', 'Allowance from Family', 'income', 'volunteer_activism', '#06B6D4'),
      ('fcat_freelance', 'Freelance', 'income', 'laptop_mac', '#6366F1'),
      ('fcat_business', 'Business', 'income', 'storefront', '#F59E0B'),
      ('fcat_scholarship', 'Scholarship', 'income', 'school', '#8B5CF6'),
      ('fcat_gift', 'Gift', 'income', 'card_giftcard', '#EC4899'),
      ('fcat_refund', 'Refund', 'income', 'replay', '#14B8A6'),
      ('fcat_other_inc', 'Other', 'income', 'attach_money', '#6B7280'),
    ];

    for (final c in categories) {
      await into(financeCategoriesTable).insertOnConflictUpdate(
        FinanceCategoriesTableCompanion.insert(
          id: c.$1,
          name: c.$2,
          type: c.$3,
          iconName: Value(c.$4),
          colorHex: Value(c.$5),
          isCustom: const Value(false),
          createdAt: Value(now),
        ),
      );
    }
  }
}
