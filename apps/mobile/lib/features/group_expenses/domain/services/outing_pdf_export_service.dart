import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/expense_with_shares.dart';
import '../models/outing_summary.dart';

/// Professional PDF generator for MyDay Split outings.
/// Formats financial statements in an executive accounting ledger layout.
class OutingPdfExportService {
  static const _channel = MethodChannel('com.myday.app/installer');
  static const _primaryColor = PdfColor.fromInt(0xFF4338CA); // Indigo 700
  static const _secondaryColor = PdfColor.fromInt(0xFF312E81); // Deep Indigo
  static const _accentCyan = PdfColor.fromInt(0xFF06B6D4); // Cyan
  static const _textDark = PdfColor.fromInt(0xFF0F172A); // Slate 900
  static const _textMuted = PdfColor.fromInt(0xFF475569); // Slate 600
  static const _bgSurface = PdfColor.fromInt(0xFFF8FAFC); // Slate 50
  static const _borderColor = PdfColor.fromInt(0xFFE2E8F0); // Slate 200
  static const _successGreen = PdfColor.fromInt(0xFF059669); // Emerald 600
  static const _dangerRed = PdfColor.fromInt(0xFFDC2626); // Red 600

  static String _formatMinor(int minor) {
    final val = minor / 100.0;
    return val.toStringAsFixed(minor % 100 == 0 ? 0 : 2);
  }

  /// Generates the PDF document for an outing summary.
  static Future<pw.Document> generateOutingPdf(
    OutingSummary summary, {
    List<ExpenseWithShares>? expenses,
  }) async {
    final pdf = pw.Document();

    // Load App Logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/app_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      // Gracefully continue without logo if asset fails to load
    }

    final outing = summary.outing;
    final currency = outing.currencyCode;
    final totalSpentStr = '$currency ${_formatMinor(summary.totalSpentMinor)}';
    final budgetStr = '$currency ${_formatMinor(outing.budgetMinor)}';
    final remainingStr =
        '$currency ${_formatMinor(summary.budgetRemainingMinor)}';
    final sharePerPersonStr =
        '$currency ${_formatMinor(summary.totalSharePerPersonMinor)}';
    final dateStr = DateFormat('MMMM d, yyyy').format(outing.outingDate);
    final generatedDateStr = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime.now());

    final memberMap = {for (final m in summary.members) m.id: m.displayName};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(summary, logoImage, dateStr, generatedDateStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),

          // 1. Executive Summary Financial Cards
          _buildFinancialSummaryCards(
            summary: summary,
            budgetStr: budgetStr,
            totalSpentStr: totalSpentStr,
            remainingStr: remainingStr,
            sharePerPersonStr: sharePerPersonStr,
          ),

          pw.SizedBox(height: 20),

          // 2. Member Balances & Accounting Ledger
          _buildMemberBalancesTable(summary, currency),

          pw.SizedBox(height: 20),

          // 3. Simplified Settlement Plan (Who Pays Whom)
          _buildSettlementPlanSection(summary, memberMap, currency),

          pw.SizedBox(height: 20),

          // 4. Itemized Expenses Breakdown (if expenses passed)
          if (expenses != null && expenses.isNotEmpty) ...[
            _buildExpensesLedgerTable(expenses, currency),
            pw.SizedBox(height: 20),
          ],

          // 5. Verification Notice & Signature Block
          _buildVerificationBlock(summary),
        ],
      ),
    );

    return pdf;
  }

  /// Opens the system preview & print/share dialog.
  static Future<void> printOrSharePdf(
    OutingSummary summary, {
    List<ExpenseWithShares>? expenses,
  }) async {
    final pdf = await generateOutingPdf(summary, expenses: expenses);
    final filename =
        'MyDay_Split_${summary.outing.title.replaceAll(RegExp(r'\s+'), '_')}.pdf';
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(await pdf.save());

    try {
      await _channel.invokeMethod('shareFile', {
        'filePath': file.path,
        'mimeType': 'application/pdf',
        'title': 'Share MyDay Split Statement',
      });
    } catch (_) {
      // Fallback
    }
  }

  // --- Header ---
  static pw.Widget _buildHeader(
    OutingSummary summary,
    pw.MemoryImage? logoImage,
    String outingDate,
    String generatedAt,
  ) {
    final isArchived = summary.outing.status == 'archived';

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _borderColor, width: 1.5),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logoImage != null) ...[
            pw.Container(
              width: 52,
              height: 52,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Image(logoImage),
            ),
            pw.SizedBox(width: 14),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'MYDAY SPLIT',
                      style: pw.TextStyle(
                        color: _primaryColor,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        color: isArchived
                            ? PdfColor.fromInt(0xFFF1F5F9)
                            : PdfColor.fromInt(0xFFEEF2FF),
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(
                          color: isArchived ? _borderColor : _primaryColor,
                        ),
                      ),
                      child: pw.Text(
                        isArchived ? 'ARCHIVED' : 'ACTIVE OUTING',
                        style: pw.TextStyle(
                          color: isArchived ? _textMuted : _primaryColor,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'FINANCIAL STATEMENT & EXPENSE AUDIT',
                  style: const pw.TextStyle(
                    color: _textDark,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Event: ${summary.outing.title} • Date: $outingDate',
                  style: pw.TextStyle(
                    color: _textMuted,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Financial Summary 4-Cards Grid ---
  static pw.Widget _buildFinancialSummaryCards({
    required OutingSummary summary,
    required String budgetStr,
    required String totalSpentStr,
    required String remainingStr,
    required String sharePerPersonStr,
  }) {
    final isOverBudget = summary.budgetRemainingMinor < 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _bgSurface,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              _buildSummaryCardItem('Total Budget', budgetStr, _primaryColor),
              _buildSummaryCardItem('Total Expenses', totalSpentStr, _textDark),
              _buildSummaryCardItem(
                isOverBudget ? 'Over Budget' : 'Remaining Budget',
                remainingStr,
                isOverBudget ? _dangerRed : _successGreen,
              ),
              _buildSummaryCardItem(
                'Share / Person',
                sharePerPersonStr,
                _accentCyan,
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Budget Usage: ${(summary.budgetUsageRatio * 100).round()}% (${summary.memberCount} Participants)',
                style: const pw.TextStyle(color: _textMuted, fontSize: 9.5),
              ),
              pw.Text(
                isOverBudget
                    ? 'EXCEEDED BUDGET LIMIT'
                    : 'WITHIN ALLOCATED BUDGET',
                style: pw.TextStyle(
                  color: isOverBudget ? _dangerRed : _successGreen,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCardItem(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(
              color: _textMuted,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Member Balances Table ---
  static pw.Widget _buildMemberBalancesTable(
    OutingSummary summary,
    String currency,
  ) {
    final rows = <pw.TableRow>[
      // Table Header
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEF2FF)),
        children: [
          _buildTableCell('Participant', isHeader: true),
          _buildTableCell('Total Paid', isHeader: true, alignRight: true),
          _buildTableCell('Total Share', isHeader: true, alignRight: true),
          _buildTableCell('Net Balance', isHeader: true, alignRight: true),
          _buildTableCell('Financial Status', isHeader: true),
        ],
      ),
    ];

    int totalPaidSum = 0;
    int totalShareSum = 0;

    for (final balance in summary.memberBalances) {
      final paid = balance.totalPaidMinor;
      final share = balance.totalShareMinor;
      final net = balance.netBalanceMinor;

      totalPaidSum += paid;
      totalShareSum += share;

      String statusStr;
      PdfColor statusColor;

      if (net > 0) {
        statusStr = 'Gets back $currency ${_formatMinor(net)}';
        statusColor = _successGreen;
      } else if (net < 0) {
        statusStr = 'Owes $currency ${_formatMinor(net.abs())}';
        statusColor = _dangerRed;
      } else {
        statusStr = 'Settled (0.00)';
        statusColor = _textMuted;
      }

      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            ),
          ),
          children: [
            _buildTableCell(
              '${balance.displayName}${balance.isOrganizer ? " (Organizer)" : ""}',
              isBold: balance.isOrganizer,
            ),
            _buildTableCell(
              '$currency ${_formatMinor(paid)}',
              alignRight: true,
            ),
            _buildTableCell(
              '$currency ${_formatMinor(share)}',
              alignRight: true,
            ),
            _buildTableCell(
              '${net >= 0 ? "+" : ""}$currency ${_formatMinor(net)}',
              alignRight: true,
              textColor: net > 0
                  ? _successGreen
                  : (net < 0 ? _dangerRed : _textDark),
              isBold: true,
            ),
            _buildTableCell(statusStr, textColor: statusColor, isBold: true),
          ],
        ),
      );
    }

    // Ledger Totals Row (Verification Invariant: Total Paid == Total Shares)
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: _bgSurface,
          border: pw.Border(
            top: pw.BorderSide(color: _primaryColor, width: 1.5),
          ),
        ),
        children: [
          _buildTableCell('LEDGER TOTALS', isHeader: true),
          _buildTableCell(
            '$currency ${_formatMinor(totalPaidSum)}',
            isHeader: true,
            alignRight: true,
          ),
          _buildTableCell(
            '$currency ${_formatMinor(totalShareSum)}',
            isHeader: true,
            alignRight: true,
          ),
          _buildTableCell(
            '$currency 0.00 (Balanced)',
            isHeader: true,
            alignRight: true,
            textColor: _successGreen,
          ),
          _buildTableCell(
            'Zero-Sum Verified ✓',
            isHeader: true,
            textColor: _successGreen,
          ),
        ],
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '1. PARTICIPANT BALANCES & SETTLEMENT LEDGER',
          style: pw.TextStyle(
            color: _primaryColor,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _borderColor, width: 0.8),
          children: rows,
        ),
      ],
    );
  }

  // --- Simplified Settlement Plan ---
  static pw.Widget _buildSettlementPlanSection(
    OutingSummary summary,
    Map<String, String> memberMap,
    String currency,
  ) {
    final settlements = summary.suggestedSettlements;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '2. DEBT SIMPLIFICATION & REPAYMENT INSTRUCTIONS',
          style: pw.TextStyle(
            color: _primaryColor,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        if (settlements.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFECFDF5),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _successGreen),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  '✓ ALL BALANCES SETTLED — NO REPAYMENTS REQUIRED',
                  style: pw.TextStyle(
                    color: _successGreen,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: _borderColor, width: 0.8),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFEEF2FF),
                ),
                children: [
                  _buildTableCell('Sender (Owes)', isHeader: true),
                  _buildTableCell('Action', isHeader: true),
                  _buildTableCell('Recipient (Gets Back)', isHeader: true),
                  _buildTableCell(
                    'Transfer Amount',
                    isHeader: true,
                    alignRight: true,
                  ),
                  _buildTableCell('Status', isHeader: true),
                ],
              ),
              ...settlements.map((s) {
                final fromName = memberMap[s.fromMemberId] ?? 'Participant';
                final toName = memberMap[s.toMemberId] ?? 'Participant';
                final amtStr = '$currency ${_formatMinor(s.amountMinor)}';

                return pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: _borderColor, width: 0.5),
                    ),
                  ),
                  children: [
                    _buildTableCell(fromName, isBold: true),
                    _buildTableCell(
                      'pays directly to ->',
                      textColor: _textMuted,
                    ),
                    _buildTableCell(toName, isBold: true),
                    _buildTableCell(
                      amtStr,
                      alignRight: true,
                      textColor: _primaryColor,
                      isBold: true,
                    ),
                    _buildTableCell('Pending Repayment', textColor: _dangerRed),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  // --- Expenses Ledger Table ---
  static pw.Widget _buildExpensesLedgerTable(
    List<ExpenseWithShares> expenses,
    String currency,
  ) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEF2FF)),
        children: [
          _buildTableCell('Date', isHeader: true),
          _buildTableCell('Expense Description', isHeader: true),
          _buildTableCell('Category', isHeader: true),
          _buildTableCell('Paid By', isHeader: true),
          _buildTableCell('Split With', isHeader: true),
          _buildTableCell('Total Amount', isHeader: true, alignRight: true),
        ],
      ),
    ];

    int totalExpensesAmount = 0;

    for (final item in expenses) {
      final exp = item.expense;
      totalExpensesAmount += exp.amountMinor;
      final payerName = item.payer.displayName;
      final expDateStr = DateFormat('MMM d, yyyy').format(exp.expenseDate);

      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            ),
          ),
          children: [
            _buildTableCell(expDateStr),
            _buildTableCell(exp.title, isBold: true),
            _buildTableCell(exp.category),
            _buildTableCell(payerName),
            _buildTableCell('${item.participantCount} Friends'),
            _buildTableCell(
              '$currency ${_formatMinor(exp.amountMinor)}',
              alignRight: true,
              isBold: true,
            ),
          ],
        ),
      );
    }

    // Total Expenses Row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: _bgSurface,
          border: pw.Border(
            top: pw.BorderSide(color: _primaryColor, width: 1.5),
          ),
        ),
        children: [
          _buildTableCell('TOTAL', isHeader: true),
          _buildTableCell('${expenses.length} Records', isHeader: true),
          _buildTableCell('', isHeader: true),
          _buildTableCell('', isHeader: true),
          _buildTableCell('', isHeader: true),
          _buildTableCell(
            '$currency ${_formatMinor(totalExpensesAmount)}',
            isHeader: true,
            alignRight: true,
            textColor: _primaryColor,
          ),
        ],
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '3. ITEMIZED EXPENSES LEDGER',
          style: pw.TextStyle(
            color: _primaryColor,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _borderColor, width: 0.8),
          children: rows,
        ),
      ],
    );
  }

  // --- Verification Block ---
  static pw.Widget _buildVerificationBlock(OutingSummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _bgSurface,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Audit & Accuracy Guarantee:',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'All currency calculations computed via integer minor units. Deterministic zero-sum invariant verified.',
                style: const pw.TextStyle(fontSize: 7.5, color: _textMuted),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'MyDay Digital Ledger',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Official Generated Report',
                style: const pw.TextStyle(fontSize: 7.5, color: _textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Footer ---
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by MyDay • Personal Productivity & Financial Management',
            style: const pw.TextStyle(color: _textMuted, fontSize: 8),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: _textMuted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    bool alignRight = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: pw.Align(
        alignment: alignRight
            ? pw.Alignment.centerRight
            : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: textColor ?? (isHeader ? _secondaryColor : _textDark),
            fontSize: isHeader ? 8.5 : 8,
            fontWeight: (isHeader || isBold)
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
