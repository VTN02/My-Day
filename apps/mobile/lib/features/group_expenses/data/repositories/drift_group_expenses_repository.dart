import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/expense_with_shares.dart';
import '../../domain/models/outing_summary.dart';
import '../../domain/repositories/group_expenses_repository.dart';
import '../../domain/services/settlement_calculator_service.dart';

class DriftGroupExpensesRepository implements GroupExpensesRepository {
  final AppDatabase _db;
  final SettlementCalculatorService _calculator;
  final Uuid _uuid;

  DriftGroupExpensesRepository(
    this._db, {
    this._calculator = const SettlementCalculatorService(),
    this._uuid = const Uuid(),
  });

  // --- Outings ---

  @override
  Stream<List<GroupOutingEntry>> watchOutings({String? status}) {
    final query = _db.select(_db.groupOutingsTable)
      ..where((tbl) {
        var predicate = tbl.deletedAt.isNull();
        if (status != null && status.isNotEmpty) {
          predicate = predicate & tbl.status.equals(status);
        }
        return predicate;
      })
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.outingDate)]);
    return query.watch();
  }

  @override
  Stream<List<GroupOutingEntry>> watchActiveOutings({int limit = 5}) {
    final query = _db.select(_db.groupOutingsTable)
      ..where((tbl) => tbl.deletedAt.isNull() & tbl.status.equals('active'))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.outingDate)])
      ..limit(limit);
    return query.watch();
  }

  @override
  Stream<GroupOutingEntry?> watchOuting(String outingId) {
    final query = _db.select(_db.groupOutingsTable)
      ..where((tbl) => tbl.id.equals(outingId) & tbl.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  @override
  Future<GroupOutingEntry?> getOuting(String outingId) {
    final query = _db.select(_db.groupOutingsTable)
      ..where((tbl) => tbl.id.equals(outingId) & tbl.deletedAt.isNull());
    return query.getSingleOrNull();
  }

  @override
  Future<GroupOutingEntry> createOuting({
    required String title,
    String description = '',
    required DateTime outingDate,
    required int budgetMinor,
    String currencyCode = 'LKR',
    required List<String> initialMemberNames,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now();
      final outingId = _uuid.v4();
      final organizerMemberId = _uuid.v4();

      // 1. Insert Outing record
      await _db
          .into(_db.groupOutingsTable)
          .insert(
            GroupOutingsTableCompanion.insert(
              id: outingId,
              organizerLocalId: organizerMemberId,
              title: title.trim(),
              description: Value(description.trim()),
              outingDate: outingDate,
              budgetMinor: Value(budgetMinor),
              currencyCode: Value(currencyCode.toUpperCase()),
              status: const Value('active'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      // 2. Insert Organizer ("You")
      await _db
          .into(_db.outingMembersTable)
          .insert(
            OutingMembersTableCompanion.insert(
              id: organizerMemberId,
              outingId: outingId,
              displayName: 'You',
              isOrganizer: const Value(true),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      // 3. Insert initial friends
      for (final rawName in initialMemberNames) {
        final cleanName = rawName.trim();
        if (cleanName.isNotEmpty && cleanName.toLowerCase() != 'you') {
          await _db
              .into(_db.outingMembersTable)
              .insert(
                OutingMembersTableCompanion.insert(
                  id: _uuid.v4(),
                  outingId: outingId,
                  displayName: cleanName,
                  isOrganizer: const Value(false),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
        }
      }

      final outing = await getOuting(outingId);
      return outing!;
    });
  }

  @override
  Future<void> updateOuting({
    required String outingId,
    required String title,
    String description = '',
    required DateTime outingDate,
    required int budgetMinor,
    required String currencyCode,
    required String status,
  }) async {
    final now = DateTime.now();
    await (_db.update(
      _db.groupOutingsTable,
    )..where((tbl) => tbl.id.equals(outingId))).write(
      GroupOutingsTableCompanion(
        title: Value(title.trim()),
        description: Value(description.trim()),
        outingDate: Value(outingDate),
        budgetMinor: Value(budgetMinor),
        currencyCode: Value(currencyCode.toUpperCase()),
        status: Value(status),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> updateOutingStatus(String outingId, String status) async {
    await (_db.update(
      _db.groupOutingsTable,
    )..where((tbl) => tbl.id.equals(outingId))).write(
      GroupOutingsTableCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteOuting(String outingId) async {
    await (_db.update(
      _db.groupOutingsTable,
    )..where((tbl) => tbl.id.equals(outingId))).write(
      GroupOutingsTableCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Members ---

  @override
  Stream<List<OutingMemberEntry>> watchMembers(String outingId) {
    final query = _db.select(_db.outingMembersTable)
      ..where((tbl) => tbl.outingId.equals(outingId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.isOrganizer),
        (tbl) => OrderingTerm.asc(tbl.displayName),
      ]);
    return query.watch();
  }

  @override
  Future<List<OutingMemberEntry>> getMembers(String outingId) {
    final query = _db.select(_db.outingMembersTable)
      ..where((tbl) => tbl.outingId.equals(outingId))
      ..orderBy([
        (tbl) => OrderingTerm.desc(tbl.isOrganizer),
        (tbl) => OrderingTerm.asc(tbl.displayName),
      ]);
    return query.get();
  }

  @override
  Future<OutingMemberEntry> addMember({
    required String outingId,
    required String displayName,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db
        .into(_db.outingMembersTable)
        .insert(
          OutingMembersTableCompanion.insert(
            id: id,
            outingId: outingId,
            displayName: displayName.trim(),
            isOrganizer: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    final member = await (_db.select(
      _db.outingMembersTable,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    return member;
  }

  @override
  Future<void> updateMemberName({
    required String memberId,
    required String newName,
  }) async {
    await (_db.update(
      _db.outingMembersTable,
    )..where((tbl) => tbl.id.equals(memberId))).write(
      OutingMembersTableCompanion(
        displayName: Value(newName.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<bool> canDeleteMember(String memberId) async {
    final member = await (_db.select(
      _db.outingMembersTable,
    )..where((tbl) => tbl.id.equals(memberId))).getSingleOrNull();
    if (member == null || member.isOrganizer) return false;

    // Check if member paid any non-deleted expenses
    final paidExpense =
        await (_db.select(_db.outingExpensesTable)
              ..where(
                (tbl) =>
                    tbl.payerMemberId.equals(memberId) & tbl.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    if (paidExpense != null) return false;

    // Check if member has shares in any non-deleted expenses
    final hasSharesQuery =
        _db.select(_db.outingExpenseSharesTable).join([
            innerJoin(
              _db.outingExpensesTable,
              _db.outingExpensesTable.id.equalsExp(
                _db.outingExpenseSharesTable.expenseId,
              ),
            ),
          ])
          ..where(
            _db.outingExpenseSharesTable.memberId.equals(memberId) &
                _db.outingExpensesTable.deletedAt.isNull(),
          )
          ..limit(1);

    final shareResult = await hasSharesQuery.get();
    if (shareResult.isNotEmpty) return false;

    // Check if member is part of any completed settlements
    final hasSettlements =
        await (_db.select(_db.outingSettlementsTable)
              ..where(
                (tbl) =>
                    (tbl.fromMemberId.equals(memberId) |
                        tbl.toMemberId.equals(memberId)) &
                    tbl.status.equals('completed'),
              )
              ..limit(1))
            .getSingleOrNull();
    if (hasSettlements != null) return false;

    return true;
  }

  @override
  Future<void> deleteMember(String memberId) async {
    final canDelete = await canDeleteMember(memberId);
    if (!canDelete) {
      throw StateError(
        'Cannot remove participant with active expenses, shares, or settlements.',
      );
    }
    await (_db.delete(
      _db.outingMembersTable,
    )..where((tbl) => tbl.id.equals(memberId))).go();
  }

  // --- Expenses ---

  @override
  Stream<List<ExpenseWithShares>> watchExpenses(String outingId) {
    final expensesStream =
        (_db.select(_db.outingExpensesTable)
              ..where(
                (tbl) => tbl.outingId.equals(outingId) & tbl.deletedAt.isNull(),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.expenseDate)]))
            .watch();

    return expensesStream.asyncMap((expenses) async {
      if (expenses.isEmpty) return const [];

      final members = await getMembers(outingId);
      final memberMap = {for (final m in members) m.id: m};
      final nameMap = {for (final m in members) m.id: m.displayName};

      final expenseIds = expenses.map((e) => e.id).toList();
      final shares = await (_db.select(
        _db.outingExpenseSharesTable,
      )..where((tbl) => tbl.expenseId.isIn(expenseIds))).get();

      final sharesByExpense = <String, List<OutingExpenseShareEntry>>{};
      for (final s in shares) {
        sharesByExpense.putIfAbsent(s.expenseId, () => []).add(s);
      }

      return expenses.map((e) {
        final payer =
            memberMap[e.payerMemberId] ??
            OutingMemberEntry(
              id: e.payerMemberId,
              outingId: outingId,
              displayName: 'Unknown',
              isOrganizer: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
        return ExpenseWithShares(
          expense: e,
          payer: payer,
          shares: sharesByExpense[e.id] ?? [],
          memberNames: nameMap,
        );
      }).toList();
    });
  }

  @override
  Future<List<ExpenseWithShares>> getExpenses(String outingId) async {
    final expenses =
        await (_db.select(_db.outingExpensesTable)
              ..where(
                (tbl) => tbl.outingId.equals(outingId) & tbl.deletedAt.isNull(),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.expenseDate)]))
            .get();

    if (expenses.isEmpty) return const [];

    final members = await getMembers(outingId);
    final memberMap = {for (final m in members) m.id: m};
    final nameMap = {for (final m in members) m.id: m.displayName};

    final expenseIds = expenses.map((e) => e.id).toList();
    final shares = await (_db.select(
      _db.outingExpenseSharesTable,
    )..where((tbl) => tbl.expenseId.isIn(expenseIds))).get();

    final sharesByExpense = <String, List<OutingExpenseShareEntry>>{};
    for (final s in shares) {
      sharesByExpense.putIfAbsent(s.expenseId, () => []).add(s);
    }

    return expenses.map((e) {
      final payer =
          memberMap[e.payerMemberId] ??
          OutingMemberEntry(
            id: e.payerMemberId,
            outingId: outingId,
            displayName: 'Unknown',
            isOrganizer: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
      return ExpenseWithShares(
        expense: e,
        payer: payer,
        shares: sharesByExpense[e.id] ?? [],
        memberNames: nameMap,
      );
    }).toList();
  }

  @override
  Stream<ExpenseWithShares?> watchExpense(String expenseId) {
    final expenseStream =
        (_db.select(_db.outingExpensesTable)..where(
              (tbl) => tbl.id.equals(expenseId) & tbl.deletedAt.isNull(),
            ))
            .watchSingleOrNull();

    return expenseStream.asyncMap((expense) async {
      if (expense == null) return null;

      final members = await getMembers(expense.outingId);
      final memberMap = {for (final m in members) m.id: m};
      final nameMap = {for (final m in members) m.id: m.displayName};

      final shares = await (_db.select(
        _db.outingExpenseSharesTable,
      )..where((tbl) => tbl.expenseId.equals(expenseId))).get();

      final payer =
          memberMap[expense.payerMemberId] ??
          OutingMemberEntry(
            id: expense.payerMemberId,
            outingId: expense.outingId,
            displayName: 'Unknown',
            isOrganizer: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      return ExpenseWithShares(
        expense: expense,
        payer: payer,
        shares: shares,
        memberNames: nameMap,
      );
    });
  }

  @override
  Future<OutingExpenseEntry> createExpense({
    required String outingId,
    required String payerMemberId,
    required String title,
    String description = '',
    required String category,
    required int amountMinor,
    required DateTime expenseDate,
    required Map<String, int> memberSharesMinor,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now();
      final expenseId = _uuid.v4();

      await _db
          .into(_db.outingExpensesTable)
          .insert(
            OutingExpensesTableCompanion.insert(
              id: expenseId,
              outingId: outingId,
              payerMemberId: payerMemberId,
              title: title.trim(),
              description: Value(description.trim()),
              category: category.toLowerCase().trim(),
              amountMinor: amountMinor,
              expenseDate: expenseDate,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      for (final entry in memberSharesMinor.entries) {
        if (entry.value > 0) {
          await _db
              .into(_db.outingExpenseSharesTable)
              .insert(
                OutingExpenseSharesTableCompanion.insert(
                  id: _uuid.v4(),
                  expenseId: expenseId,
                  memberId: entry.key,
                  amountMinor: entry.value,
                ),
              );
        }
      }

      final expense = await (_db.select(
        _db.outingExpensesTable,
      )..where((tbl) => tbl.id.equals(expenseId))).getSingle();
      return expense;
    });
  }

  @override
  Future<void> updateExpense({
    required String expenseId,
    required String payerMemberId,
    required String title,
    String description = '',
    required String category,
    required int amountMinor,
    required DateTime expenseDate,
    required Map<String, int> memberSharesMinor,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now();

      await (_db.update(
        _db.outingExpensesTable,
      )..where((tbl) => tbl.id.equals(expenseId))).write(
        OutingExpensesTableCompanion(
          payerMemberId: Value(payerMemberId),
          title: Value(title.trim()),
          description: Value(description.trim()),
          category: Value(category.toLowerCase().trim()),
          amountMinor: Value(amountMinor),
          expenseDate: Value(expenseDate),
          updatedAt: Value(now),
        ),
      );

      // Re-create shares
      await (_db.delete(
        _db.outingExpenseSharesTable,
      )..where((tbl) => tbl.expenseId.equals(expenseId))).go();

      for (final entry in memberSharesMinor.entries) {
        if (entry.value > 0) {
          await _db
              .into(_db.outingExpenseSharesTable)
              .insert(
                OutingExpenseSharesTableCompanion.insert(
                  id: _uuid.v4(),
                  expenseId: expenseId,
                  memberId: entry.key,
                  amountMinor: entry.value,
                ),
              );
        }
      }
    });
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await (_db.update(
      _db.outingExpensesTable,
    )..where((tbl) => tbl.id.equals(expenseId))).write(
      OutingExpensesTableCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Settlements ---

  @override
  Stream<List<OutingSettlementEntry>> watchSettlements(String outingId) {
    final query = _db.select(_db.outingSettlementsTable)
      ..where((tbl) => tbl.outingId.equals(outingId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.settlementDate)]);
    return query.watch();
  }

  @override
  Future<List<OutingSettlementEntry>> getSettlements(String outingId) {
    final query = _db.select(_db.outingSettlementsTable)
      ..where((tbl) => tbl.outingId.equals(outingId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.settlementDate)]);
    return query.get();
  }

  @override
  Future<OutingSettlementEntry> recordSettlement({
    required String outingId,
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
    required DateTime settlementDate,
    String note = '',
    String paymentMethod = 'cash',
  }) async {
    if (fromMemberId == toMemberId) {
      throw ArgumentError('Payer and receiver cannot be the same participant.');
    }
    if (amountMinor <= 0) {
      throw ArgumentError('Settlement amount must be greater than zero.');
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await _db
        .into(_db.outingSettlementsTable)
        .insert(
          OutingSettlementsTableCompanion.insert(
            id: id,
            outingId: outingId,
            fromMemberId: fromMemberId,
            toMemberId: toMemberId,
            amountMinor: amountMinor,
            settlementDate: settlementDate,
            note: Value(note.trim()),
            paymentMethod: Value(paymentMethod.trim()),
            status: const Value('completed'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return (_db.select(
      _db.outingSettlementsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  @override
  Future<void> reverseSettlement(String settlementId) async {
    await (_db.update(
      _db.outingSettlementsTable,
    )..where((tbl) => tbl.id.equals(settlementId))).write(
      OutingSettlementsTableCompanion(
        status: const Value('reversed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Financial Summary Stream ---

  @override
  Stream<OutingSummary?> watchOutingSummary(String outingId) {
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            _db.groupOutingsTable,
            _db.outingExpensesTable,
            _db.outingExpenseSharesTable,
            _db.outingSettlementsTable,
            _db.outingMembersTable,
          },
        )
        .watch()
        .asyncMap((_) async {
          final outing = await getOuting(outingId);
          if (outing == null) return null;

          final members = await getMembers(outingId);
          final activeExpenses =
              await (_db.select(_db.outingExpensesTable)..where(
                    (tbl) =>
                        tbl.outingId.equals(outingId) & tbl.deletedAt.isNull(),
                  ))
                  .get();

          final expenseIds = activeExpenses.map((e) => e.id).toList();
          final activeShares = expenseIds.isEmpty
              ? <OutingExpenseShareEntry>[]
              : await (_db.select(
                  _db.outingExpenseSharesTable,
                )..where((tbl) => tbl.expenseId.isIn(expenseIds))).get();

          final settlements = await getSettlements(outingId);

          return _calculator.summarizeOuting(
            outing: outing,
            members: members,
            activeExpenses: activeExpenses,
            activeShares: activeShares,
            completedSettlements: settlements,
          );
        });
  }
}
