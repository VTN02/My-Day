import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/repositories/drift_group_expenses_repository.dart';
import '../../domain/models/expense_with_shares.dart';
import '../../domain/models/outing_summary.dart';
import '../../domain/repositories/group_expenses_repository.dart';

/// Provider for GroupExpensesRepository singleton.
final groupExpensesRepositoryProvider = Provider<GroupExpensesRepository>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return DriftGroupExpensesRepository(db);
});

/// Streams all active outings.
final activeOutingsStreamProvider = StreamProvider<List<GroupOutingEntry>>((
  ref,
) {
  return ref.watch(groupExpensesRepositoryProvider).watchActiveOutings();
});

/// Streams outings filtered by optional status ('active', 'completed', 'archived', or null for all).
final outingsByStatusStreamProvider =
    StreamProvider.family<List<GroupOutingEntry>, String?>((ref, status) {
      return ref
          .watch(groupExpensesRepositoryProvider)
          .watchOutings(status: status);
    });

/// Streams a single outing by ID.
final outingDetailStreamProvider =
    StreamProvider.family<GroupOutingEntry?, String>((ref, outingId) {
      return ref.watch(groupExpensesRepositoryProvider).watchOuting(outingId);
    });

/// Streams participants for an outing.
final outingMembersStreamProvider =
    StreamProvider.family<List<OutingMemberEntry>, String>((ref, outingId) {
      return ref.watch(groupExpensesRepositoryProvider).watchMembers(outingId);
    });

/// Streams expenses with shares for an outing.
final outingExpensesStreamProvider =
    StreamProvider.family<List<ExpenseWithShares>, String>((ref, outingId) {
      return ref.watch(groupExpensesRepositoryProvider).watchExpenses(outingId);
    });

/// Streams an individual expense with shares by ID.
final expenseDetailStreamProvider =
    StreamProvider.family<ExpenseWithShares?, String>((ref, expenseId) {
      return ref.watch(groupExpensesRepositoryProvider).watchExpense(expenseId);
    });

/// Streams all recorded settlements for an outing.
final outingSettlementsStreamProvider =
    StreamProvider.family<List<OutingSettlementEntry>, String>((ref, outingId) {
      return ref
          .watch(groupExpensesRepositoryProvider)
          .watchSettlements(outingId);
    });

/// Streams the comprehensive financial summary & balances for an outing.
final outingSummaryStreamProvider =
    StreamProvider.family<OutingSummary?, String>((ref, outingId) {
      return ref
          .watch(groupExpensesRepositoryProvider)
          .watchOutingSummary(outingId);
    });
