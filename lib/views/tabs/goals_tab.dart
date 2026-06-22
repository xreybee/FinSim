import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/finance_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/goal_model.dart';
import '../widgets/glassmorphism_widgets.dart';
import '../goal_detail_page.dart';

class GoalsTab extends StatefulWidget {
  const GoalsTab({super.key});

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  // Indonesian custom currency formatter
  String _formatIDR(double amount) {
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

  void _showAddGoalDialog(FinanceController finance) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final initialSavingsController = TextEditingController(text: '0');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    final themeCtrl = Provider.of<ThemeController>(context, listen: false);
    final isDark = themeCtrl.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF003025) : const Color(0xFFF5F9F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isDark ? const Color(0x33FFFFFF) : const Color(0x18000000), width: 1.5),
          ),
          title: Text(
            'Tambah Impian Baru 🎯',
            style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    labelText: 'Nama Impian / Barang',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF546E7A)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    labelText: 'Target Harga (IDR)',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF546E7A)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: initialSavingsController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    labelText: 'Tabungan Awal (IDR)',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF546E7A)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tenggat Waktu:', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF546E7A))),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month, color: Color(0xFF00BFA5)),
                      label: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Batal', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF546E7A))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final target = double.tryParse(targetController.text) ?? 0.0;
                final initial = double.tryParse(initialSavingsController.text) ?? 0.0;

                if (name.isEmpty || target <= 0) return;

                await finance.addGoal(name, target, initial, selectedDate);
                if (mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceController>(context);
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = themeCtrl.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white70 : const Color(0xFF546E7A);
    final sub54 = isDark ? Colors.white54 : const Color(0xFF90A4AE);
    final progressBg = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target progress overall goals limit indicator
            GlassCard(
              child: Column(
                children: [
                  Text(
                    'Tabungan Impian Bulanan',
                    style: GoogleFonts.outfit(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Terkumpul: ${_formatIDR(finance.totalSavingsInGoals)} / ${_formatIDR(finance.limitGoals)}',
                    style: TextStyle(color: subColor, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: finance.limitGoals > 0
                          ? (finance.totalSavingsInGoals / finance.limitGoals).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: progressBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Goals list section title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Target Impian',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                TextButton.icon(
                  onPressed: () => _showAddGoalDialog(finance),
                  icon: const Icon(Icons.add, size: 18, color: Color(0xFF00BFA5)),
                  label: Text('Tambah', style: GoogleFonts.outfit(color: const Color(0xFF00BFA5), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (finance.goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Column(
                  children: [
                    Icon(Icons.stars, color: sub54, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada target impian yang ditambahkan.',
                      style: GoogleFonts.inter(color: sub54, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final double width = MediaQuery.of(context).size.width;
                  final bool isWide = width >= 600;

                  if (!isWide) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: finance.goals.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildGoalCard(context, finance.goals[index], isDark, textColor, subColor, sub54, progressBg),
                        );
                      },
                    );
                  } else {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.45,
                      ),
                      itemCount: finance.goals.length,
                      itemBuilder: (context, index) {
                        return _buildGoalCard(context, finance.goals[index], isDark, textColor, subColor, sub54, progressBg);
                      },
                    );
                  }
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalModel goal, bool isDark, Color textColor, Color subColor, Color sub54, Color progressBg) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GoalDetailPage(goalId: goal.id)),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: goal.isCompleted
                        ? const Color(0x3300E676)
                        : const Color(0x1F00BFA5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${goal.percent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: goal.isCompleted
                          ? const Color(0xFF00E676)
                          : const Color(0xFF00BFA5),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TERKUMPUL', style: TextStyle(color: sub54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(_formatIDR(goal.currentSavings), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TARGET HARGA', style: TextStyle(color: sub54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(_formatIDR(goal.targetPrice), style: TextStyle(color: subColor, fontSize: 12)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: progressBg,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.isCompleted ? 'Target Tercapai! 🏆' : 'Kekurangan: ${_formatIDR(goal.targetPrice - goal.currentSavings)}',
                    style: GoogleFonts.inter(
                      color: goal.isCompleted ? const Color(0xFF00E676) : subColor,
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}',
                  style: TextStyle(color: sub54, fontSize: 9.5),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
