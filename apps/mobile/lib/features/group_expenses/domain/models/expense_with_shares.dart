import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';

/// Aggregates an outing expense with its payer details and individual participant shares.
@immutable
class ExpenseWithShares {
  final OutingExpenseEntry expense;
  final OutingMemberEntry payer;
  final List<OutingExpenseShareEntry> shares;
  final Map<String, String> memberNames; // memberId -> displayName

  const ExpenseWithShares({
    required this.expense,
    required this.payer,
    required this.shares,
    this.memberNames = const {},
  });

  int get participantCount => shares.length;
}
