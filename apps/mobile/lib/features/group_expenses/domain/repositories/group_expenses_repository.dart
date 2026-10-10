import '../../../../core/database/app_database.dart';
import '../models/expense_with_shares.dart';
import '../models/outing_summary.dart';

/// Repository interface for MyDay Split group outing expenses & settlements.
abstract class GroupExpensesRepository {
  // --- Outings ---
  Stream<List<GroupOutingEntry>> watchOutings({String? status});
  Stream<List<GroupOutingEntry>> watchActiveOutings({int limit = 5});
  Stream<GroupOutingEntry?> watchOuting(String outingId);
  Future<GroupOutingEntry?> getOuting(String outingId);

  Future<GroupOutingEntry> createOuting({
    required String title,
    String description = '',
    required DateTime outingDate,
    required int budgetMinor,
    String currencyCode = 'LKR',
    required List<String> initialMemberNames,
  });

  Future<void> updateOuting({
    required String outingId,
    required String title,
    String description = '',
    required DateTime outingDate,
    required int budgetMinor,
    required String currencyCode,
    required String status,
  });

  Future<void> updateOutingStatus(String outingId, String status);
  Future<void> deleteOuting(String outingId);

  // --- Members ---
  Stream<List<OutingMemberEntry>> watchMembers(String outingId);
  Future<List<OutingMemberEntry>> getMembers(String outingId);
  Future<OutingMemberEntry> addMember({
    required String outingId,
    required String displayName,
  });
  Future<void> updateMemberName({
    required String memberId,
    required String newName,
  });
  Future<bool> canDeleteMember(String memberId);
  Future<void> deleteMember(String memberId);

  // --- Expenses ---
  Stream<List<ExpenseWithShares>> watchExpenses(String outingId);
  Future<List<ExpenseWithShares>> getExpenses(String outingId);
  Stream<ExpenseWithShares?> watchExpense(String expenseId);
  Future<OutingExpenseEntry> createExpense({
    required String outingId,
    required String payerMemberId,
    required String title,
    String description = '',
    required String category,
    required int amountMinor,
    required DateTime expenseDate,
    required Map<String, int> memberSharesMinor,
  });
  Future<void> updateExpense({
    required String expenseId,
    required String payerMemberId,
    required String title,
    String description = '',
    required String category,
    required int amountMinor,
    required DateTime expenseDate,
    required Map<String, int> memberSharesMinor,
  });
  Future<void> deleteExpense(String expenseId);

  // --- Settlements (Repayments) ---
  Stream<List<OutingSettlementEntry>> watchSettlements(String outingId);
  Future<List<OutingSettlementEntry>> getSettlements(String outingId);
  Future<OutingSettlementEntry> recordSettlement({
    required String outingId,
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
    required DateTime settlementDate,
    String note = '',
    String paymentMethod = 'cash',
  });
  Future<void> reverseSettlement(String settlementId);

  // --- Financial Summary Stream ---
  Stream<OutingSummary?> watchOutingSummary(String outingId);
}
