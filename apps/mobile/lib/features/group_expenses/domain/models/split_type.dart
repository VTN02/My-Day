/// Supported split methods for an outing expense.
enum SplitType {
  equal,
  customAmount,
  percentage;

  String get displayName {
    switch (this) {
      case SplitType.equal:
        return 'Equal';
      case SplitType.customAmount:
        return 'Custom Amount';
      case SplitType.percentage:
        return 'Percentage';
    }
  }
}
