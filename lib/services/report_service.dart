import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../models/user_model.dart';
import '../controllers/finance_controller.dart';

class ReportService {
  // Indonesian custom currency formatter for reports
  static String _formatIDR(double amount) {
    if (amount.isNaN || amount.isInfinite) return 'Rp 0';
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
      count++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  /// Generate a PDF report representing the full state of budget health, goals and transactions.
  static Future<String> generatePdfReport(FinanceController finance) async {
    final pdf = pw.Document();

    final profile = finance.userProfile ?? UserModel(uid: 'unknown', email: 'guest@finsim.com', monthlySalary: 0.0, profession: '');
    final goals = finance.goals;
    final transactions = finance.transactions;

    final printDate = DateTime.now();
    final formattedPrintDate = "${printDate.day}/${printDate.month}/${printDate.year} ${printDate.hour}:${printDate.minute.toString().padLeft(2, '0')}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // TITLE SECTION
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'finsim - Laporan Keuangan Pribadi',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal),
                  ),
                  pw.Text(
                    formattedPrintDate,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // PROFILE SUMMARY
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.tealAccent, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.teal50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PROFIL PENGGUNA', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Email: ${profile.email}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Profesi: ${profile.profession.isNotEmpty ? profile.profession : "-"}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Gaji Bulanan: ${_formatIDR(finance.monthlySalary)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        'Sisa Saldo Umum: ${_formatIDR(finance.overallRemainingBalance)}',
                        style: pw.TextStyle(
                          fontSize: 10, 
                          fontWeight: pw.FontWeight.bold,
                          color: finance.overallRemainingBalance >= 0 ? PdfColors.green : PdfColors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // BUDGET STATUS SECTION
            pw.Text('RINGKASAN ALOKASI ANGGARAN (METODE 6 POS)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Pos Anggaran', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Alokasi Ideal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Terpakai', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Sisa Saldo Pos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Status Health', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  ],
                ),
                // Rows
                _buildPdfBudgetRow('Survival (Bertahan Hidup - 40%)', finance.limitSurvival, finance.spendingSurvival, finance.remainingSurvival, finance.getCategoryStatus('Survival')['status']),
                _buildPdfBudgetRow('Transportasi (10%)', finance.limitTransport, finance.spendingTransport, finance.remainingTransport, finance.getCategoryStatus('Transportasi')['status']),
                _buildPdfBudgetRow('Gaya Hidup / Style (10%)', finance.limitStyle, finance.spendingStyle, finance.remainingStyle, finance.getCategoryStatus('Style')['status']),
                _buildPdfBudgetRow('Hiburan (10%)', finance.limitEntertainment, finance.spendingEntertainment, finance.remainingEntertainment, finance.getCategoryStatus('Hiburan')['status']),
                _buildPdfBudgetRow('Dana Darurat (10%)', finance.limitEmergency, finance.spendingEmergency, finance.remainingEmergency, finance.getCategoryStatus('Dana Darurat')['status']),
                _buildPdfBudgetRow('Goals & Investasi (20%)', finance.limitGoals, finance.totalSavingsInGoals, finance.remainingGoals, finance.getCategoryStatus('Goals')['status']),
              ],
            ),
            pw.SizedBox(height: 24),

            // GOALS SECTION
            pw.Text('IMPIAN KEUANGAN & TARGET TABUNGAN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (goals.isEmpty)
              pw.Text('Belum ada impian keuangan yang terdaftar.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Nama Impian', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Target Harga', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Dana Terkumpul', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Kekurangan Dana', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Progres (%)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    ],
                  ),
                  ...goals.map((g) {
                    final remaining = g.targetPrice - g.currentSavings;
                    final remStr = remaining > 0 ? _formatIDR(remaining) : "Lunas 🎉";
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(g.name, style: const pw.TextStyle(fontSize: 8.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatIDR(g.targetPrice), style: const pw.TextStyle(fontSize: 8.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatIDR(g.currentSavings), style: const pw.TextStyle(fontSize: 8.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(remStr, style: const pw.TextStyle(fontSize: 8.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${g.percent.toStringAsFixed(0)}%", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: g.isCompleted ? PdfColors.green : PdfColors.teal))),
                      ],
                    );
                  }).toList()
                ],
              ),
            pw.SizedBox(height: 24),

            // TRANSACTIONS HISTORY
            pw.Text('RIWAYAT TRANSAKSI TERAKHIR', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (transactions.isEmpty)
              pw.Text('Belum ada riwayat transaksi pengeluaran.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Tanggal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Kategori', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Keterangan / Catatan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    ],
                  ),
                  ...transactions.map((t) {
                    final dateStr = "${t.date.day}/${t.date.month}/${t.date.year}";
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 8.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(t.category, style: const pw.TextStyle(fontSize: 8.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(t.note.isNotEmpty ? t.note : "-", style: const pw.TextStyle(fontSize: 8.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("- ${_formatIDR(t.amount)}", style: pw.TextStyle(color: PdfColors.red800, fontWeight: pw.FontWeight.bold, fontSize: 8.5))),
                      ],
                    );
                  }).toList()
                ],
              ),
          ];
        },
      ),
    );

    // Save document
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/finsim_laporan_${printDate.millisecondsSinceEpoch}.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  static pw.TableRow _buildPdfBudgetRow(String pos, double limit, double spending, double remaining, String status) {
    final statusColor = status == 'Sehat' ? PdfColors.green800 : PdfColors.red800;
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(pos, style: const pw.TextStyle(fontSize: 8.5))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatIDR(limit), style: const pw.TextStyle(fontSize: 8.5))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatIDR(spending), style: const pw.TextStyle(fontSize: 8.5))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatIDR(remaining), style: const pw.TextStyle(fontSize: 8.5))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(status, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: statusColor, fontSize: 8.5))),
      ],
    );
  }

  /// Generate an Excel workbook representing the full budget breakdown, goals and transaction logs.
  static Future<String> generateExcelReport(FinanceController finance) async {
    final excel = Excel.createExcel();

    final profile = finance.userProfile ?? UserModel(uid: 'unknown', email: 'guest@finsim.com', monthlySalary: 0.0, profession: '');
    final goals = finance.goals;
    final transactions = finance.transactions;

    // 1. RINGKASAN ANGGARAN SHEET
    final String overviewSheetName = 'Ringkasan Anggaran';
    excel.rename(excel.getDefaultSheet()!, overviewSheetName);
    final Sheet overviewSheet = excel[overviewSheetName];

    // Write title & metadata
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('LAPORAN KEUANGAN FINSIM');
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Email: ${profile.email}');
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('Profesi: ${profile.profession}');
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = TextCellValue('Gaji Bulanan: ${_formatIDR(finance.monthlySalary)}');
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = TextCellValue('Sisa Saldo Bersih: ${_formatIDR(finance.overallRemainingBalance)}');
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = TextCellValue('Tanggal Cetak: ${DateTime.now()}');

    // Budget Table Headers
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).value = TextCellValue('Pos Anggaran');
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7)).value = TextCellValue('Batas Anggaran');
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 7)).value = TextCellValue('Total Pengeluaran');
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 7)).value = TextCellValue('Sisa Anggaran Pos');
    overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 7)).value = TextCellValue('Status');

    final budgetRows = [
      ['Survival (Bertahan Hidup - 40%)', finance.limitSurvival, finance.spendingSurvival, finance.remainingSurvival, finance.getCategoryStatus('Survival')['status']],
      ['Transportasi (10%)', finance.limitTransport, finance.spendingTransport, finance.remainingTransport, finance.getCategoryStatus('Transportasi')['status']],
      ['Gaya Hidup / Style (10%)', finance.limitStyle, finance.spendingStyle, finance.remainingStyle, finance.getCategoryStatus('Style')['status']],
      ['Hiburan (10%)', finance.limitEntertainment, finance.spendingEntertainment, finance.remainingEntertainment, finance.getCategoryStatus('Hiburan')['status']],
      ['Dana Darurat (10%)', finance.limitEmergency, finance.spendingEmergency, finance.remainingEmergency, finance.getCategoryStatus('Dana Darurat')['status']],
      ['Goals & Investasi (20%)', finance.limitGoals, finance.totalSavingsInGoals, finance.remainingGoals, finance.getCategoryStatus('Goals')['status']],
    ];

    for (int i = 0; i < budgetRows.length; i++) {
      final r = budgetRows[i];
      final rIndex = 8 + i;
      overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIndex)).value = TextCellValue(r[0] as String);
      overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIndex)).value = DoubleCellValue(r[1] as double);
      overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIndex)).value = DoubleCellValue(r[2] as double);
      overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rIndex)).value = DoubleCellValue(r[3] as double);
      overviewSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rIndex)).value = TextCellValue(r[4] as String);
    }

    // 2. GOALS SHEET
    final String goalsSheetName = 'Impian & Tabungan';
    final Sheet goalsSheet = excel[goalsSheetName];

    goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('DAFTAR IMPIAN KEUANGAN (GOALS)');
    goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('Nama Impian');
    goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value = TextCellValue('Target Harga');
    goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2)).value = TextCellValue('Dana Terkumpul');
    goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 2)).value = TextCellValue('Sisa Kekurangan');
    goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2)).value = TextCellValue('Progres (%)');
    goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 2)).value = TextCellValue('Tenggat Waktu');

    for (int i = 0; i < goals.length; i++) {
      final g = goals[i];
      final rIndex = 3 + i;
      final remaining = g.targetPrice - g.currentSavings;

      goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIndex)).value = TextCellValue(g.name);
      goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIndex)).value = DoubleCellValue(g.targetPrice);
      goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIndex)).value = DoubleCellValue(g.currentSavings);
      goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rIndex)).value = DoubleCellValue(remaining > 0 ? remaining : 0.0);
      goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rIndex)).value = DoubleCellValue(g.percent);
      goalsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rIndex)).value = TextCellValue("${g.deadline.day}/${g.deadline.month}/${g.deadline.year}");
    }

    // 3. TRANSACTIONS SHEET
    final String transSheetName = 'Daftar Transaksi';
    final Sheet transSheet = excel[transSheetName];

    transSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('RIWAYAT PENGELUARAN HARIAN');
    transSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('Tanggal');
    transSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value = TextCellValue('Kategori');
    transSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2)).value = TextCellValue('Keterangan');
    transSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 2)).value = TextCellValue('Jumlah Uang');

    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      final rIndex = 3 + i;
      transSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIndex)).value = TextCellValue("${t.date.day}/${t.date.month}/${t.date.year}");
      transSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIndex)).value = TextCellValue(t.category);
      transSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIndex)).value = TextCellValue(t.note);
      transSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rIndex)).value = DoubleCellValue(t.amount);
    }

    // Save workbook bytes
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/finsim_laporan_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    final file = File(path);
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }
    return path;
  }
}
