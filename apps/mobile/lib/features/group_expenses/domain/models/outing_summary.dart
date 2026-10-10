import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import 'member_balance.dart';
import 'suggested_settlement.dart';

/// Comprehensive financial summary of an outing.
@immutable
class OutingSummary {
  final GroupOutingEntry outing;
  final List<OutingMemberEntry> members;
  final int totalSpentMinor;
  final int budgetRemainingMinor;
  final double budgetUsageRatio;
  final int totalSharePerPersonMinor;
  final List<MemberBalance> memberBalances;
  final List<SuggestedSettlement> suggestedSettlements;
  final int totalOutstandingDebtMinor;

  const OutingSummary({
    required this.outing,
    required this.members,
    required this.totalSpentMinor,
    required this.budgetRemainingMinor,
    required this.budgetUsageRatio,
    required this.totalSharePerPersonMinor,
    required this.memberBalances,
    required this.suggestedSettlements,
    required this.totalOutstandingDebtMinor,
  });

  int get memberCount => members.length;

  /// Balance for the organizer ("You")
  MemberBalance? get myBalance {
    try {
      return memberBalances.firstWhere((b) => b.isOrganizer);
    } catch (_) {
      return memberBalances.isNotEmpty ? memberBalances.first : null;
    }
  }
}
