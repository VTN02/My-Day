import 'package:flutter/foundation.dart';

/// Represents a recommended direct repayment between two participants
/// calculated by the greedy min-cash-flow algorithm.
@immutable
class SuggestedSettlement {
  final String fromMemberId;
  final String fromDisplayName;
  final String toMemberId;
  final String toDisplayName;
  final int amountMinor;

  const SuggestedSettlement({
    required this.fromMemberId,
    required this.fromDisplayName,
    required this.toMemberId,
    required this.toDisplayName,
    required this.amountMinor,
  });
}
