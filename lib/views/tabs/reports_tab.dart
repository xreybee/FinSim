import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/finance_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../services/report_service.dart';
import '../widgets/glassmorphism_widgets.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  bool _isPdfLoading = false;
  bool _isExcelLoading = false;
  String? _pdfPath;
  String? _excelPath;

  void _exportPdf(FinanceController finance) async {
    setState(() {
      _isPdfLoading = true;
      _pdfPath = null;
    });

    try {
      final path = await ReportService.generatePdfReport(finance);
      setState(() {
        _pdfPath = path;
        _isPdfLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan PDF berhasil dibuat!'),
            backgroundColor: Color(0xFF00BFA5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isPdfLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _exportExcel(FinanceController finance) async {
    setState(() {
      _isExcelLoading = true;
      _excelPath = null;
    });

    try {
      final path = await ReportService.generateExcelReport(finance);
      setState(() {
        _excelPath = path;
        _isExcelLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan Excel berhasil dibuat!'),
            backgroundColor: Color(0xFF00BFA5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExcelLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor Excel: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildPdfCard(FinanceController finance, bool isDark, Color textColor, Color subColor) {
    final pathBg = isDark ? Colors.black26 : Colors.black.withOpacity(0.04);
    final pathBorder = isDark ? Colors.white10 : Colors.black.withOpacity(0.08);
    final pathLabel = isDark ? Colors.white38 : const Color(0xFF90A4AE);
    final pathText = isDark ? Colors.white70 : const Color(0xFF546E7A);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
              const SizedBox(width: 10),
              Text(
                'Ekspor Format PDF',
                style: GoogleFonts.outfit(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Dokumen PDF yang rapi, berformat tabel resmi, cocok untuk dibagikan atau dicetak langsung.',
            style: TextStyle(color: subColor, fontSize: 11.5, height: 1.3),
          ),
          const SizedBox(height: 16),
          _isPdfLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
              : GlassButton(
                  color: Colors.redAccent,
                  onPressed: () => _exportPdf(finance),
                  child: Text('UNDUH DOKUMEN PDF', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
          if (_pdfPath != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pathBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: pathBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PDF disimpan di:', style: TextStyle(color: pathLabel, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  SelectableText(
                    _pdfPath!,
                    style: GoogleFonts.inter(color: pathText, fontSize: 10.5),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildExcelCard(FinanceController finance, bool isDark, Color textColor, Color subColor) {
    final pathBg = isDark ? Colors.black26 : Colors.black.withOpacity(0.04);
    final pathBorder = isDark ? Colors.white10 : Colors.black.withOpacity(0.08);
    final pathLabel = isDark ? Colors.white38 : const Color(0xFF90A4AE);
    final pathText = isDark ? Colors.white70 : const Color(0xFF546E7A);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart, color: Colors.greenAccent, size: 24),
              const SizedBox(width: 10),
              Text(
                'Ekspor Format Excel (.xlsx)',
                style: GoogleFonts.outfit(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'File spreadsheet yang berisi lembar tab terpisah untuk profil ringkasan pos, daftar target impian, dan log transaksi lengkap untuk dianalisis lebih lanjut.',
            style: TextStyle(color: subColor, fontSize: 11.5, height: 1.3),
          ),
          const SizedBox(height: 16),
          _isExcelLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
              : GlassButton(
                  color: Colors.green,
                  onPressed: () => _exportExcel(finance),
                  child: Text('UNDUH TEMPLATE EXCEL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
          if (_excelPath != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pathBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: pathBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Excel disimpan di:', style: TextStyle(color: pathLabel, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  SelectableText(
                    _excelPath!,
                    style: GoogleFonts.inter(color: pathText, fontSize: 10.5),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceController>(context);
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = themeCtrl.isDarkMode;
    final salary = finance.monthlySalary;
    final double width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 600;

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white70 : const Color(0xFF546E7A);

    if (salary <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Lengkapi Gaji Anda di tab Ringkasan terlebih dahulu sebelum dapat mengunduh laporan keuangan.',
            style: TextStyle(color: subColor, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Info
          GlassCard(
            backgroundColor: const Color(0x1A00BFA5),
            borderColor: const Color(0x3300BFA5),
            child: Column(
              children: [
                const Icon(Icons.description_outlined, size: 44, color: Color(0xFF00BFA5)),
                const SizedBox(height: 12),
                Text(
                  'Unduh Analisis Keuangan',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 6),
                Text(
                  'Unduh laporan lengkap yang berisi data alokasi pos anggaran cerdas, daftar impian target tabungan, dan riwayat seluruh transaksi pengeluaran bulanan Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subColor, fontSize: 12, height: 1.4),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!isWide) ...[
            _buildPdfCard(finance, isDark, textColor, subColor),
            const SizedBox(height: 20),
            _buildExcelCard(finance, isDark, textColor, subColor),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPdfCard(finance, isDark, textColor, subColor)),
                const SizedBox(width: 20),
                Expanded(child: _buildExcelCard(finance, isDark, textColor, subColor)),
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
