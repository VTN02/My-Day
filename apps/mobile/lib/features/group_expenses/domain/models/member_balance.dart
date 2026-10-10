import 'package:flutter/foundation.dart';

/// Represents a participant's complete balance sheet in an outing.
@immutable
class MemberBalance {
  final String memberId;
  final String displayName;
  final bool isOrganizer;
  final int totalPaidMinor;
  final int totalShareMinor;
  final int repaymentsSentMinor;
  final int repaymentsReceivedMinor;

  const MemberBalance({
    required this.memberId,
    required this.displayName,
    this.isOrganizer = false,
    required this.totalPaidMinor,
    required this.totalShareMinor,
    this.repaymentsSentMinor = 0,
    this.repaymentsReceivedMinor = 0,
  });

  /// Net balance before any settlements: Total Paid - Total Share
  int get netBeforeRepaymentsMinor => totalPaidMinor - totalShareMinor;

  /// Effective net balance after settlements:
  /// (Total Paid - Total Share) + Repayments Sent - Repayments Received
  int get netBalanceMinor =>
      netBeforeRepaymentsMinor + repaymentsSentMinor - repaymentsReceivedMinor;

  /// Whether this member is completely settled up (net balance == 0)
  bool get isSettled => netBalanceMinor == 0;

  /// Whether this member should receive money back (net balance > 0)
  bool get isCreditor => netBalanceMinor > 0;

  /// Whether this member owes money to the group (net balance < 0)
  bool get isDebtor => netBalanceMinor < 0;

  /// Outstanding amount owed by debtor (positive magnitude)
  int get outstandingDebtMinor => isDebtor ? -netBalanceMinor : 0;

  /// Outstanding amount to be received by creditor (positive magnitude)
  int get outstandingCreditMinor => isCreditor ? netBalanceMinor : 0;
}
