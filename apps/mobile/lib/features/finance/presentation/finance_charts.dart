import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Interactive Donut Pie Chart displaying category expense distributions.
class FinanceExpenseDonutChart extends StatelessWidget {
  final Map<String, int> categoryTotals;
  final int totalExpenseCents;
  final bool isDark;

  const FinanceExpenseDonutChart({
    super.key,
    required this.categoryTotals,
    required this.totalExpenseCents,
    required this.isDark,
  });

  String _formatCents(int cents) {
    final val = cents / 100.0;
    return 'Rs. ${val.toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
  }

  Color _getCategoryColor(int index) {
    const palette = [
      AppColors.primaryIndigo,
      AppColors.secondaryViolet,
      AppColors.accentCyan,
      AppColors.warningAmber,
      AppColors.errorCoral,
      AppColors.successMint,
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
    ];
    return palette[index % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty || totalExpenseCents == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardSurface
              : AppColors.lightCardSurface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Center(
          child: Text(
            'No expense data to chart yet.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText,
            ),
          ),
        ),
      );
    }

    final entries = categoryTotals.entries.toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expense Breakdown',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.errorCoral.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  '${entries.length} Categories',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.errorCoral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Donut Ring Chart Center
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _DonutChartPainter(
                      entries: entries,
                      total: totalExpenseCents,
                      getColor: _getCategoryColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Spent',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCents(totalExpenseCents),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(entries.length, (i) {
              final e = entries[i];
              final pct = ((e.value / totalExpenseCents) * 100).round();
              final color = _getCategoryColor(i);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${e.key} ($pct%)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int total;
  final Color Function(int) getColor;

  _DonutChartPainter({
    required this.entries,
    required this.total,
    required this.getColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < entries.length; i++) {
      final sweepAngle = (entries[i].value / total) * 2 * math.pi;
      // Slight gap between segments
      final gap = entries.length > 1 ? 0.05 : 0.0;
      final effectiveSweep = math.max(0.01, sweepAngle - gap);

      paint.color = getColor(i);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + gap / 2,
        effectiveSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

/// Dual Bar Chart comparing Income vs Expenses side-by-side.
class FinanceCashFlowBarChart extends StatelessWidget {
  final int totalIncomeCents;
  final int totalExpenseCents;
  final List<FinancialTransactionEntry> recentTransactions;
  final bool isDark;

  const FinanceCashFlowBarChart({
    super.key,
    required this.totalIncomeCents,
    required this.totalExpenseCents,
    required this.recentTransactions,
    required this.isDark,
  });

  String _formatCents(int cents) {
    final val = cents / 100.0;
    return 'Rs. ${val.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = math.max(totalIncomeCents, totalExpenseCents);
    final incomeRatio = maxVal > 0 ? (totalIncomeCents / maxVal) : 0.0;
    final expenseRatio = maxVal > 0 ? (totalExpenseCents / maxVal) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income vs Expense Ratio',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText,
                ),
              ),
              Row(
                children: [
                  _buildLegend(AppColors.successMint, 'Income'),
                  const SizedBox(width: 10),
                  _buildLegend(AppColors.errorCoral, 'Expense'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Vertical comparison bars
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Income Bar Column
                _buildBarColumn(
                  label: 'Income',
                  amount: _formatCents(totalIncomeCents),
                  ratio: incomeRatio,
                  color: AppColors.successMint,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                // Expense Bar Column
                _buildBarColumn(
                  label: 'Expense',
                  amount: _formatCents(totalExpenseCents),
                  ratio: expenseRatio,
                  color: AppColors.errorCoral,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Net Savings Pill
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Cash Flow',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
                Text(
                  _formatCents(totalIncomeCents - totalExpenseCents),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: totalIncomeCents >= totalExpenseCents
                        ? AppColors.successMint
                        : AppColors.errorCoral,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildBarColumn({
    required String label,
    required String amount,
    required double ratio,
    required Color color,
    required Gradient gradient,
  }) {
    const maxHeight = 100.0;
    final barHeight = math.max(12.0, maxHeight * ratio);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 54,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
          ),
        ),
      ],
    );
  }
}
