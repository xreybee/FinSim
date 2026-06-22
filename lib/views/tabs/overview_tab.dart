import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/finance_controller.dart';
import '../../controllers/theme_controller.dart';
import '../widgets/glassmorphism_widgets.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  // Indonesian custom currency formatter
  String _formatIDR(double amount) {
    if (amount.isNaN || amount.isInfinite) return 'Rp 0';
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final str = absAmount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
      count++;
    }
    final formatted = 'Rp ${buffer.toString().split('').reversed.join('')}';
    return isNegative ? '- $formatted' : formatted;
  }

  void _showEditProfileDialog(BuildContext context, FinanceController finance) {
    final salaryController = TextEditingController(
      text: finance.monthlySalary > 0 ? finance.monthlySalary.toStringAsFixed(0) : '',
    );
    final professionController = TextEditingController(
      text: finance.userProfile?.profession ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF003025),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x33FFFFFF), width: 1.5),
        ),
        title: Text(
          'Atur Profil & Gaji',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: salaryController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Gaji Bulanan (IDR)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00BFA5)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: professionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Profesi',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00BFA5)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final salary = double.tryParse(salaryController.text) ?? 0.0;
              final prof = professionController.text.trim();
              await finance.updateProfile(salary, prof);
              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceController>(context);
    final themeNotifier = Provider.of<ThemeController>(context);
    final isDark = themeNotifier.isDarkMode;

    final salary = finance.monthlySalary;
    final balance = finance.overallRemainingBalance;
    final isNegativeBalance = balance < 0;

    final double width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 720; // Tablet and Laptop breakpoint

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isWide) ...[
            // Side-by-side Row for profile & clean balance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProfileCard(finance, isDark, textColor, subColor)),
                if (salary > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(child: _buildOverallBalanceCard(balance, isNegativeBalance, isDark, textColor, subColor)),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            // Vertical stack for mobile
            _buildProfileCard(finance, isDark, textColor, subColor),
            const SizedBox(height: 20),
            if (salary > 0) ...[
              _buildOverallBalanceCard(balance, isNegativeBalance, isDark, textColor, subColor),
              const SizedBox(height: 20),
            ],
          ],

          if (salary <= 0)
            _buildEmptySalaryCard(finance, isDark, textColor, subColor)
          else ...[
            if (isWide) ...[
              // Side-by-side Row for warning alert board & budget Pie Chart
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildAdvisorySection(finance, isDark, textColor, subColor)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildBudgetPieSection(finance, isDark, textColor, subColor)),
                ],
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Vertical stack for mobile
              _buildAdvisorySection(finance, isDark, textColor, subColor),
              const SizedBox(height: 20),
              _buildBudgetPieSection(finance, isDark, textColor, subColor),
              const SizedBox(height: 20),
            ],
            // Dynamic bar chart comparison
            _buildExpenseVsLimitChart(finance, isDark),
            const SizedBox(height: 24),
          ]
        ],
      ),
    );
  }

  Widget _buildExpenseVsLimitChart(FinanceController finance, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF546E7A);

    final categories = [
      {'name': 'Surv', 'spent': finance.spendingSurvival, 'limit': finance.limitSurvival, 'color': const Color(0xFF00BFA5)},
      {'name': 'Tran', 'spent': finance.spendingTransport, 'limit': finance.limitTransport, 'color': const Color(0xFF29B6F6)},
      {'name': 'Styl', 'spent': finance.spendingStyle, 'limit': finance.limitStyle, 'color': const Color(0xFFEC407A)},
      {'name': 'Ent', 'spent': finance.spendingEntertainment, 'limit': finance.limitEntertainment, 'color': const Color(0xFFFFA726)},
      {'name': 'Emer', 'spent': finance.spendingEmergency, 'limit': finance.limitEmergency, 'color': const Color(0xFFEF5350)},
    ];

    double maxVal = 1000000.0;
    for (var cat in categories) {
      final spent = cat['spent'] as double;
      final limit = cat['limit'] as double;
      if (spent > maxVal) maxVal = spent;
      if (limit > maxVal) maxVal = limit;
    }
    maxVal = ((maxVal / 1000000).ceil() * 1000000).toDouble();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Analisis Pengeluaran vs Batas Pos (Rp Juta)',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF003025),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final cat = categories[group.x.toInt()];
                      final isSpent = rodIndex == 0;
                      final type = isSpent ? 'Terpakai' : 'Batas';
                      return BarTooltipItem(
                        '${cat['name']}\n$type: ${_formatIDR(rod.toY)}',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= categories.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            categories[idx]['name'] as String,
                            style: TextStyle(color: labelColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        final millions = value / 1000000;
                        if (millions % 1 != 0) return const SizedBox();
                        return Text(
                          '${millions.toStringAsFixed(0)}M',
                          style: TextStyle(color: labelColor, fontSize: 9),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(categories.length, (idx) {
                  final cat = categories[idx];
                  final spent = cat['spent'] as double;
                  final limit = cat['limit'] as double;
                  final color = cat['color'] as Color;

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: spent,
                        color: spent > limit ? Colors.redAccent : color,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: limit,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(FinanceController finance, bool isDark, Color textColor, Color subColor) {
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF00BFA5).withOpacity(0.2),
            child: const Icon(Icons.person, color: Color(0xFF00BFA5), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finance.userProfile?.profession.isNotEmpty == true
                      ? finance.userProfile!.profession
                      : 'Profesi belum diatur',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  finance.monthlySalary > 0
                      ? 'Gaji Bulanan: ${_formatIDR(finance.monthlySalary)}'
                      : 'Gaji Bulanan belum diatur',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF00BFA5)),
            onPressed: () => _showEditProfileDialog(context, finance),
          )
        ],
      ),
    );
  }

  Widget _buildEmptySalaryCard(FinanceController finance, bool isDark, Color textColor, Color subColor) {
    return GlassCard(
      backgroundColor: isDark ? const Color(0x2BFFD54F) : const Color(0x7FFFFD54),
      borderColor: const Color(0x66FFD54F),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet, size: 48, color: Colors.amberAccent),
          const SizedBox(height: 12),
          Text(
            'Lengkapi Profil Keuangan Anda',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan isi Gaji Bulanan Anda terlebih dahulu agar Finsim dapat mengalokasikan 6 pos anggaran pintar secara otomatis.',
            textAlign: TextAlign.center,
            style: TextStyle(color: subColor, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _showEditProfileDialog(context, finance),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Atur Gaji Sekarang',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOverallBalanceCard(double balance, bool isNegative, bool isDark, Color textColor, Color subColor) {
    return GlassCard(
      backgroundColor: isNegative
          ? (isDark ? const Color(0x2BFF1744) : const Color(0x66FF1744))
          : (isDark ? const Color(0x1F00E676) : const Color(0x5900E676)),
      borderColor: isNegative
          ? const Color(0x80FF1744)
          : const Color(0x6600E676),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Sisa Saldo Umum (Bersih)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isNegative ? Icons.trending_down : Icons.account_balance,
                color: isNegative ? Colors.redAccent : const Color(0xFF00E676),
                size: 20,
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatIDR(balance),
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isNegative ? const Color(0xFFFF8A80) : const Color(0xFF00E676),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isNegative
                ? 'Pengeluaran total Anda melebihi jumlah gaji bulan ini. Harap segera kurangi pengeluaran gaya hidup/hiburan Anda!'
                : 'Sisa uang kas Anda setelah dialokasikan ke 5 pos spending dan tabungan impian Anda aman.',
            style: TextStyle(color: subColor, fontSize: 11, height: 1.4),
          )
        ],
      ),
    );
  }

  Widget _buildAdvisorySection(FinanceController finance, bool isDark, Color textColor, Color subColor) {
    final warnings = finance.getWarnings();
    final bool isAllHealthy = warnings.isEmpty;

    return GlassCard(
      backgroundColor: isAllHealthy
          ? (isDark ? const Color(0x1500E676) : const Color(0x4000E676))
          : (isDark ? const Color(0x2BFF1744) : const Color(0x66FF1744)),
      borderColor: isAllHealthy
          ? const Color(0x4000E676)
          : const Color(0x80FF1744),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAllHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                color: isAllHealthy ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAllHealthy ? 'Evaluasi: Keuangan Sehat' : 'Evaluasi: Kurang Sehat',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isAllHealthy)
            Text(
              'Hebat! Seluruh pos pengeluaran bulanan Anda berada di dalam batas aman alokasi ideal pos Anda.',
              style: GoogleFonts.inter(color: subColor, fontSize: 12.5, height: 1.4),
            )
          else ...[
            Text(
              'Saran penasihat finansial untuk menstabilkan kondisi anggaran Anda:',
              style: GoogleFonts.inter(color: subColor, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: warnings.map((warn) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          warn,
                          style: TextStyle(color: textColor, fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetPieSection(FinanceController finance, bool isDark, Color textColor, Color subColor) {
    const cSurvival = Color(0xFF00BFA5);
    const cTransport = Color(0xFF29B6F6);
    const cStyle = Color(0xFFEC407A);
    const cEntertainment = Color(0xFFFFA726);
    const cEmergency = Color(0xFFEF5350);
    const cGoals = Color(0xFF66BB6A);

    final sPct = finance.survivalPct;
    final tPct = finance.transportPct;
    final stPct = finance.stylePct;
    final ePct = finance.entertainmentPct;
    final emPct = finance.emergencyPct;
    final gPct = finance.goalsPct;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Struktur Rencana Anggaran (${sPct.toStringAsFixed(0)}/${tPct.toStringAsFixed(0)}/${stPct.toStringAsFixed(0)}/${ePct.toStringAsFixed(0)}/${emPct.toStringAsFixed(0)}/${gPct.toStringAsFixed(0)})',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: sPct > 0 ? sPct : 1, color: cSurvival, radius: 25, showTitle: false),
                  PieChartSectionData(value: tPct > 0 ? tPct : 1, color: cTransport, radius: 25, showTitle: false),
                  PieChartSectionData(value: stPct > 0 ? stPct : 1, color: cStyle, radius: 25, showTitle: false),
                  PieChartSectionData(value: ePct > 0 ? ePct : 1, color: cEntertainment, radius: 25, showTitle: false),
                  PieChartSectionData(value: emPct > 0 ? emPct : 1, color: cEmergency, radius: 25, showTitle: false),
                  PieChartSectionData(value: gPct > 0 ? gPct : 1, color: cGoals, radius: 25, showTitle: false),
                ],
                centerSpaceRadius: 46,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegend('Survival (${sPct.toStringAsFixed(0)}%)', cSurvival, subColor),
              _buildLegend('Transport (${tPct.toStringAsFixed(0)}%)', cTransport, subColor),
              _buildLegend('Style (${stPct.toStringAsFixed(0)}%)', cStyle, subColor),
              _buildLegend('Hiburan (${ePct.toStringAsFixed(0)}%)', cEntertainment, subColor),
              _buildLegend('Darurat (${emPct.toStringAsFixed(0)}%)', cEmergency, subColor),
              _buildLegend('Goals (${gPct.toStringAsFixed(0)}%)', cGoals, subColor),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(String text, Color color, Color subColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: subColor, fontSize: 11),
        ),
      ],
    );
  }
}
