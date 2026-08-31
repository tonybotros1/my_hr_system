import 'dart:js_interop';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;

import '../models/payroll/payroll_run_model.dart';

class PayrollRunDocumentService {
  const PayrollRunDocumentService();

  Future<Uint8List> buildPayslip({
    required PayrollRunDetails run,
    required PayrollRunEmployee employee,
    required Map<String, dynamic> company,
  }) async {
    final document = pw.Document();
    final companyName = _text(company['company_name'], fallback: 'Company');
    final currency = _text(company['currency_code'], fallback: 'AED');
    final periodDates = [
      _dateOnly(run.periodStartDate),
      _dateOnly(run.periodEndDate),
    ].where((value) => value.isNotEmpty).join(' - ');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on ${_dateOnly(DateTime.now().toIso8601String())}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Text(
                'PAYSLIP',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              color: PdfColors.grey100,
            ),
            child: pw.Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _headerField('Employee', employee.employeeName),
                _headerField('Employee No.', employee.employeeNumber),
                _headerField('Payroll', run.payrollName),
                _headerField('Period', run.periodName),
                _headerField(
                  'Period Dates',
                  periodDates.isEmpty ? run.periodName : periodDates,
                ),
                _headerField('Run No.', run.runNumber),
                _headerField('Payment No.', run.paymentNumber),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _summaryBox(
                'Total Payments',
                '${formatAmount(employee.totalPayments)} $currency',
                PdfColors.green700,
              ),
              pw.SizedBox(width: 8),
              _summaryBox(
                'Total Deductions',
                '${formatAmount(employee.totalDeductions)} $currency',
                PdfColors.red700,
              ),
              pw.SizedBox(width: 8),
              _summaryBox(
                'Net Salary',
                '${formatAmount(employee.netSalary)} $currency',
                PdfColors.blue700,
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Payroll Elements'),
          _payrollElementsTable(employee.payrollElements, currency),
          if (employee.informationElements.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Balances'),
            _informationElementsTable(employee.informationElements),
          ],
          pw.SizedBox(height: 28),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _signatureLine('Prepared By'),
              _signatureLine('Employee Signature'),
            ],
          ),
        ],
      ),
    );

    return document.save();
  }

  String buildBankCsv({
    required PayrollRunDetails run,
    required List<PayrollRunEmployee> employees,
    required Map<String, dynamic> company,
  }) {
    final currency = _text(company['currency_code'], fallback: 'AED');
    final headers = [
      'Run Number',
      'Payment Number',
      'Payroll',
      'Period',
      'Period Start',
      'Period End',
      'Employee Number',
      'Employee Name',
      'Bank Name',
      'Account Number',
      'IBAN',
      'SWIFT Code',
      'Currency',
      'Net Salary',
      'Status',
    ];
    final rows = employees.map(
      (employee) => [
        run.runNumber,
        run.paymentNumber,
        run.payrollName,
        run.periodName,
        _dateOnly(run.periodStartDate),
        _dateOnly(run.periodEndDate),
        employee.employeeNumber,
        employee.employeeName,
        employee.bankName,
        employee.accountNumber,
        employee.iban,
        employee.swiftCode,
        currency,
        employee.netSalary.toStringAsFixed(2),
        hasBankDetails(employee) ? 'Ready' : 'Missing bank details',
      ],
    );
    return [_csvRow(headers), ...rows.map(_csvRow)].join('\r\n');
  }

  void downloadBankCsv(String contents, PayrollRunDetails run) {
    final fileName =
        'bank_export_${_safeFilePart(run.runNumber, 'payroll-run')}_${_safeFilePart(run.periodName, 'period')}.csv';
    final blob = web.Blob(
      [contents.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    web.HTMLAnchorElement()
      ..href = objectUrl
      ..download = fileName
      ..click();
    web.URL.revokeObjectURL(objectUrl);
  }

  bool hasBankDetails(PayrollRunEmployee employee) {
    final hasBankName = employee.bankName.trim().isNotEmpty;
    final hasAccount = employee.accountNumber.trim().isNotEmpty;
    final hasIban = employee.iban.trim().isNotEmpty;
    return hasBankName && (hasAccount || hasIban);
  }

  String formatAmount(num value) {
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }
    return '${value < 0 ? '-' : ''}$buffer.${parts.last}';
  }

  pw.Widget _headerField(String label, String value) {
    return pw.SizedBox(
      width: 150,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(_text(value), style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 0.7),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _payrollElementsTable(
    List<PayrollRunElement> elements,
    String currency,
  ) {
    final rows = elements.isEmpty
        ? [
            ['No payroll elements', '', '', '', ''],
          ]
        : elements
              .map(
                (element) => [
                  _text(element.name),
                  _text(element.type),
                  _optionalNumber(element.number),
                  '${formatAmount(element.payment)} $currency',
                  '${formatAmount(element.deduction)} $currency',
                ],
              )
              .toList();
    return pw.TableHelper.fromTextArray(
      headers: const ['Element', 'Type', 'Number', 'Payment', 'Deduction'],
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      cellAlignments: const {
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _informationElementsTable(List<PayrollRunElement> elements) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Element', 'Number', 'Value'],
      data: elements
          .map(
            (element) => [
              _text(element.name),
              _optionalNumber(element.number),
              _optionalNumber(element.information),
            ],
          )
          .toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      cellAlignments: const {
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _signatureLine(String label) {
    return pw.SizedBox(
      width: 190,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 0.5, color: PdfColors.grey600),
          pw.SizedBox(height: 5),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  String _optionalNumber(num value) => value == 0 ? '' : formatAmount(value);

  String _text(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _dateOnly(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
    return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _csvRow(Iterable<dynamic> values) {
    return values
        .map((value) {
          final escaped = (value?.toString() ?? '').replaceAll('"', '""');
          return '"$escaped"';
        })
        .join(',');
  }

  String _safeFilePart(String value, String fallback) {
    final clean = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return clean.isEmpty ? fallback : clean;
  }
}
