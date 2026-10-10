import '../../../../core/database/app_database.dart';
import '../models/member_balance.dart';
import '../models/outing_summary.dart';
import '../models/suggested_settlement.dart';

/// Pure domain service calculating member net balances and optimal settlement transfers
/// adhering strictly to integer arithmetic and zero-sum invariants.
class SettlementCalculatorService {
  const SettlementCalculatorService();

  /// Calculates individual member balances given the outing's active ledger.
  List<MemberBalance> calculateMemberBalances({
    required List<OutingMemberEntry> members,
    required List<OutingExpenseEntry> activeExpenses,
    required List<OutingExpenseShareEntry> activeShares,
    required List<OutingSettlementEntry> completedSettlements,
  }) {
    if (members.isEmpty) return const [];

    // 1. Calculate Total Paid per member
    final paidMap = <String, int>{for (final m in members) m.id: 0};
    for (final expense in activeExpenses) {
      if (paidMap.containsKey(expense.payerMemberId)) {
        paidMap[expense.payerMemberId] =
            paidMap[expense.payerMemberId]! + expense.amountMinor;
      }
    }

    // 2. Calculate Total Share per member
    final shareMap = <String, int>{for (final m in members) m.id: 0};
    for (final share in activeShares) {
      if (shareMap.containsKey(share.memberId)) {
        shareMap[share.memberId] =
            shareMap[share.memberId]! + share.amountMinor;
      }
    }

    // 3. Calculate Repayments Sent and Received per member
    final sentMap = <String, int>{for (final m in members) m.id: 0};
    final receivedMap = <String, int>{for (final m in members) m.id: 0};
    for (final settlement in completedSettlements) {
      if (settlement.status == 'completed') {
        if (sentMap.containsKey(settlement.fromMemberId)) {
          sentMap[settlement.fromMemberId] =
              sentMap[settlement.fromMemberId]! + settlement.amountMinor;
        }
        if (receivedMap.containsKey(settlement.toMemberId)) {
          receivedMap[settlement.toMemberId] =
              receivedMap[settlement.toMemberId]! + settlement.amountMinor;
        }
      }
    }

    // 4. Construct MemberBalance objects
    final balances = <MemberBalance>[];
    var netSum = 0;

    for (final member in members) {
      final balance = MemberBalance(
        memberId: member.id,
        displayName: member.displayName,
        isOrganizer: member.isOrganizer,
        totalPaidMinor: paidMap[member.id] ?? 0,
        totalShareMinor: shareMap[member.id] ?? 0,
        repaymentsSentMinor: sentMap[member.id] ?? 0,
        repaymentsReceivedMinor: receivedMap[member.id] ?? 0,
      );
      balances.add(balance);
      netSum += balance.netBalanceMinor;
    }

    // Invariant Check: Sum of net balances must be zero
    assert(
      netSum == 0,
      'Zero-sum invariant violated! Sum of net balances is $netSum, expected 0.',
    );

    return balances;
  }

  /// Calculates a greedy minimal set of suggested settlement transactions
  /// to eliminate all outstanding debts.
  List<SuggestedSettlement> calculateSuggestedSettlements(
    List<MemberBalance> balances,
  ) {
    if (balances.isEmpty) return const [];

    // Map for fast name lookups
    final nameMap = {for (final b in balances) b.memberId: b.displayName};

    // Separate into creditors (> 0) and debtors (< 0)
    final creditors = <_TempBalance>[];
    final debtors = <_TempBalance>[];

    for (final b in balances) {
      if (b.netBalanceMinor > 0) {
        creditors.add(_TempBalance(b.memberId, b.netBalanceMinor));
      } else if (b.netBalanceMinor < 0) {
        debtors.add(
          _TempBalance(b.memberId, -b.netBalanceMinor),
        ); // store positive magnitude
      }
    }

    // Sort descending by amount to greedily pair largest debtor with largest creditor
    creditors.sort((a, b) => b.amount.compareTo(a.amount));
    debtors.sort((a, b) => b.amount.compareTo(a.amount));

    final settlements = <SuggestedSettlement>[];

    var cIndex = 0;
    var dIndex = 0;

    while (cIndex < creditors.length && dIndex < debtors.length) {
      final creditor = creditors[cIndex];
      final debtor = debtors[dIndex];

      final settleAmount = creditor.amount < debtor.amount
          ? creditor.amount
          : debtor.amount;

      if (settleAmount > 0) {
        settlements.add(
          SuggestedSettlement(
            fromMemberId: debtor.memberId,
            fromDisplayName: nameMap[debtor.memberId] ?? 'Unknown',
            toMemberId: creditor.memberId,
            toDisplayName: nameMap[creditor.memberId] ?? 'Unknown',
            amountMinor: settleAmount,
          ),
        );
      }

      creditor.amount -= settleAmount;
      debtor.amount -= settleAmount;

      if (creditor.amount == 0) cIndex++;
      if (debtor.amount == 0) dIndex++;
    }

    return settlements;
  }

  /// Produces a complete financial summary of the outing.
  OutingSummary summarizeOuting({
    required GroupOutingEntry outing,
    required List<OutingMemberEntry> members,
    required List<OutingExpenseEntry> activeExpenses,
    required List<OutingExpenseShareEntry> activeShares,
    required List<OutingSettlementEntry> completedSettlements,
  }) {
    final balances = calculateMemberBalances(
      members: members,
      activeExpenses: activeExpenses,
      activeShares: activeShares,
      completedSettlements: completedSettlements,
    );

    final totalSpent = activeExpenses.fold<int>(
      0,
      (sum, e) => sum + e.amountMinor,
    );

    final budgetRemaining = outing.budgetMinor - totalSpent;
    final budgetUsage = outing.budgetMinor > 0
        ? (totalSpent / outing.budgetMinor).clamp(0.0, 5.0)
        : 0.0;

    final sharePerPerson = members.isNotEmpty
        ? totalSpent ~/ members.length
        : 0;

    final suggested = calculateSuggestedSettlements(balances);

    final totalDebt = balances.fold<int>(
      0,
      (sum, b) => sum + b.outstandingDebtMinor,
    );

    return OutingSummary(
      outing: outing,
      members: members,
      totalSpentMinor: totalSpent,
      budgetRemainingMinor: budgetRemaining,
      budgetUsageRatio: budgetUsage,
      totalSharePerPersonMinor: sharePerPerson,
      memberBalances: balances,
      suggestedSettlements: suggested,
      totalOutstandingDebtMinor: totalDebt,
    );
  }
}

class _TempBalance {
  final String memberId;
  int amount;

  _TempBalance(this.memberId, this.amount);
}
