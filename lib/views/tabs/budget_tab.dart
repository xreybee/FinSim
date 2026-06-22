import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/finance_controller.dart';
import '../../controllers/theme_controller.dart';
import '../widgets/glassmorphism_widgets.dart';

class BudgetTab extends StatefulWidget {
  const BudgetTab({super.key});

  @override
  State<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<BudgetTab> {
  bool _showCustomAllocation = false;

  late TextEditingController _survivalCtrl;
  late TextEditingController _transportCtrl;
  late TextEditingController _styleCtrl;
  late TextEditingController _entertainmentCtrl;
  late TextEditingController _emergencyCtrl;
  late TextEditingController _goalsCtrl;
  bool _isSaving = false;
  bool _initialized = false;

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

  void _initControllers(FinanceController finance) {
    if (_initialized) return;
    _survivalCtrl = TextEditingController(text: finance.survivalPct.toStringAsFixed(0));
    _transportCtrl = TextEditingController(text: finance.transportPct.toStringAsFixed(0));
    _styleCtrl = TextEditingController(text: finance.stylePct.toStringAsFixed(0));
    _entertainmentCtrl = TextEditingController(text: finance.entertainmentPct.toStringAsFixed(0));
    _emergencyCtrl = TextEditingController(text: finance.emergencyPct.toStringAsFixed(0));
    _goalsCtrl = TextEditingController(text: finance.goalsPct.toStringAsFixed(0));
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _survivalCtrl.dispose();
      _transportCtrl.dispose();
      _styleCtrl.dispose();
      _entertainmentCtrl.dispose();
      _emergencyCtrl.dispose();
      _goalsCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _saveBudgetRule(FinanceController finance) async {
    final s = double.tryParse(_survivalCtrl.text) ?? 0;
    final t = double.tryParse(_transportCtrl.text) ?? 0;
    final st = double.tryParse(_styleCtrl.text) ?? 0;
    final e = double.tryParse(_entertainmentCtrl.text) ?? 0;
    final em = double.tryParse(_emergencyCtrl.text) ?? 0;
    final g = double.tryParse(_goalsCtrl.text) ?? 0;
    final total = s + t + st + e + em + g;

    if (total != 100.0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Total harus 100% (saat ini: ${total.toStringAsFixed(0)}%)'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await finance.updateBudgetRule(
        survival: s, transport: t, style: st,
        entertainment: e, emergency: em, goals: g,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alokasi anggaran berhasil disimpan! 🎉'), backgroundColor: Color(0xFF00BFA5)),
        );
        setState(() => _showCustomAllocation = false);
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $err'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceController>(context);
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = themeCtrl.isDarkMode;
    final salary = finance.monthlySalary;

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white70 : const Color(0xFF546E7A);
    final sub54 = isDark ? Colors.white54 : const Color(0xFF90A4AE);

    _initControllers(finance);

    if (salary <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Lengkapi Gaji Anda di tab Ringkasan untuk melihat pembagian 6 pos anggaran.',
            style: TextStyle(color: subColor, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    const cSurvival = Color(0xFF00BFA5);
    const cTransport = Color(0xFF29B6F6);
    const cStyle = Color(0xFFEC407A);
    const cEntertainment = Color(0xFFFFA726);
    const cEmergency = Color(0xFFEF5350);
    const cGoals = Color(0xFF66BB6A);

    final double width = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (width >= 1000) {
      crossAxisCount = 3;
    } else if (width >= 620) {
      crossAxisCount = 2;
    }

    final cards = [
      _buildBudgetPosCard('Survival (${finance.survivalPct.toStringAsFixed(0)}%)', finance.spendingSurvival, finance.limitSurvival, finance.remainingSurvival, finance.getCategoryStatus('Survival')['status'], cSurvival, isDark, textColor, subColor, sub54),
      _buildBudgetPosCard('Transportasi (${finance.transportPct.toStringAsFixed(0)}%)', finance.spendingTransport, finance.limitTransport, finance.remainingTransport, finance.getCategoryStatus('Transportasi')['status'], cTransport, isDark, textColor, subColor, sub54),
      _buildBudgetPosCard('Gaya Hidup (${finance.stylePct.toStringAsFixed(0)}%)', finance.spendingStyle, finance.limitStyle, finance.remainingStyle, finance.getCategoryStatus('Style')['status'], cStyle, isDark, textColor, subColor, sub54),
      _buildBudgetPosCard('Hiburan (${finance.entertainmentPct.toStringAsFixed(0)}%)', finance.spendingEntertainment, finance.limitEntertainment, finance.remainingEntertainment, finance.getCategoryStatus('Hiburan')['status'], cEntertainment, isDark, textColor, subColor, sub54),
      _buildBudgetPosCard('Dana Darurat (${finance.emergencyPct.toStringAsFixed(0)}%)', finance.spendingEmergency, finance.limitEmergency, finance.remainingEmergency, finance.getCategoryStatus('Dana Darurat')['status'], cEmergency, isDark, textColor, subColor, sub54),
      _buildBudgetPosCard('Goals & Investasi (${finance.goalsPct.toStringAsFixed(0)}%)', finance.totalSavingsInGoals, finance.limitGoals, finance.remainingGoals, finance.getCategoryStatus('Goals')['status'], cGoals, isDark, textColor, subColor, sub54, isGoal: true),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title row with custom allocation button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Batas & Sisa Anggaran Per Pos',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showCustomAllocation = !_showCustomAllocation;
                    if (_showCustomAllocation) {
                      // Refresh controllers with latest values
                      _survivalCtrl.text = finance.survivalPct.toStringAsFixed(0);
                      _transportCtrl.text = finance.transportPct.toStringAsFixed(0);
                      _styleCtrl.text = finance.stylePct.toStringAsFixed(0);
                      _entertainmentCtrl.text = finance.entertainmentPct.toStringAsFixed(0);
                      _emergencyCtrl.text = finance.emergencyPct.toStringAsFixed(0);
                      _goalsCtrl.text = finance.goalsPct.toStringAsFixed(0);
                    }
                  });
                },
                icon: Icon(
                  _showCustomAllocation ? Icons.close : Icons.tune,
                  size: 18,
                  color: const Color(0xFF00BFA5),
                ),
                label: Text(
                  _showCustomAllocation ? 'Tutup' : 'Atur Alokasi',
                  style: GoogleFonts.outfit(color: const Color(0xFF00BFA5), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom allocation card (collapsible)
          if (_showCustomAllocation)
            _buildCustomAllocationCard(finance, isDark, textColor, subColor),

          if (crossAxisCount == 1)
            Column(children: cards)
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: width >= 1200 ? 1.6 : 1.35,
              children: cards,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCustomAllocationCard(FinanceController finance, bool isDark, Color textColor, Color subColor) {
    final fillColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.45);
    final borderColor = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12);

    Widget pctField(String label, IconData icon, Color iconColor, TextEditingController ctrl) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: GoogleFonts.inter(color: subColor, fontSize: 13))),
            SizedBox(
              width: 70,
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: TextStyle(color: subColor, fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00BFA5)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: fillColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFF00BFA5), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Alokasi Anggaran Kustom', style: GoogleFonts.outfit(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Total harus tepat 100%.', style: GoogleFonts.inter(color: subColor, fontSize: 11)),
            const SizedBox(height: 16),
            pctField('Survival (Makanan)', Icons.restaurant, const Color(0xFF00BFA5), _survivalCtrl),
            pctField('Transportasi', Icons.directions_car, const Color(0xFF29B6F6), _transportCtrl),
            pctField('Gaya Hidup', Icons.shopping_bag, const Color(0xFFEC407A), _styleCtrl),
            pctField('Hiburan', Icons.confirmation_number, const Color(0xFFFFA726), _entertainmentCtrl),
            pctField('Dana Darurat', Icons.health_and_safety, const Color(0xFFEF5350), _emergencyCtrl),
            pctField('Tabungan Impian', Icons.savings, const Color(0xFF66BB6A), _goalsCtrl),
            const SizedBox(height: 12),
            _isSaving
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)))
                : GlassButton(
                    onPressed: () => _saveBudgetRule(finance),
                    child: Text('SIMPAN ALOKASI', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetPosCard(
    String title,
    double actual,
    double limit,
    double remaining,
    String status,
    Color color,
    bool isDark,
    Color textColor,
    Color subColor,
    Color sub54, {
    bool isGoal = false,
  }) {
    final bool isOver = isGoal
        ? (actual < limit && limit > 0)
        : (actual > limit);
    final percentUsed = limit > 0 ? (actual / limit * 100) : 0.0;
    final statusColor = isOver ? Colors.redAccent : const Color(0xFF00E676);
    final progressBg = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        borderColor: isOver
            ? Colors.redAccent.withOpacity(0.35)
            : color.withOpacity(0.22),
        backgroundColor: isOver
            ? Colors.redAccent.withOpacity(0.06)
            : color.withOpacity(0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5), width: 0.5),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TERPAKAI', style: TextStyle(color: sub54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(_formatIDR(actual), style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('BATAS', style: TextStyle(color: sub54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(_formatIDR(limit), style: GoogleFonts.inter(color: subColor, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(isGoal ? 'KURANG' : 'SISA', style: TextStyle(color: sub54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      _formatIDR(remaining < 0 && !isGoal ? 0 : remaining),
                      style: GoogleFonts.inter(
                        color: isGoal
                            ? (isOver ? Colors.orangeAccent : const Color(0xFF00E676))
                            : (isOver ? Colors.redAccent : const Color(0xFF00E676)),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: limit > 0 ? (actual / limit).clamp(0.0, 1.0) : 0.0,
                      backgroundColor: progressBg,
                      valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.redAccent : color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${percentUsed.toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(
                    color: isOver ? Colors.redAccent : textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
