import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/finance_controller.dart';
import 'widgets/glassmorphism_widgets.dart';

class GoalDetailPage extends StatefulWidget {
  final String goalId;

  const GoalDetailPage({super.key, required this.goalId});

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  final _savingsController = TextEditingController();

  @override
  void dispose() {
    _savingsController.dispose();
    super.dispose();
  }

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

  void _addSavings(FinanceController finance) async {
    final amt = double.tryParse(_savingsController.text) ?? 0.0;
    if (amt <= 0) return;

    await finance.addSavingsToGoal(widget.goalId, amt);
    _savingsController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil menambahkan tabungan sebesar ${_formatIDR(amt)}!',
          ),
          backgroundColor: const Color(0xFF00BFA5),
        ),
      );
    }
  }

  void _deleteGoal(FinanceController finance) async {
    final name = finance.goals.firstWhere((g) => g.id == widget.goalId).name;
    await finance.deleteGoal(widget.goalId);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Impian "$name" telah dihapus.')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceController>(context);

    // Find the goal in the controller's list
    final goalIndex = finance.goals.indexWhere((g) => g.id == widget.goalId);

    if (goalIndex == -1) {
      return Scaffold(
        body: BubbleBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Impian tidak ditemukan atau telah dihapus.',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                GlassButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali ke Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final goal = finance.goals[goalIndex];
    final remaining = goal.targetPrice - goal.currentSavings;
    final double remainingClamped = remaining < 0 ? 0 : remaining;

    return Scaffold(
      body: BubbleBackground(
        child: SafeArea(
          child: Column(
            children: [
              // HEADER ROW
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Rincian Impian',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF003025),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(color: Colors.white24),
                            ),
                            title: const Text(
                              'Hapus Impian 🗑️',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              'Apakah Anda yakin ingin menghapus target impian "${goal.name}"?',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _deleteGoal(finance);
                                },
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // MAIN VIEW
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TITLE CARD
                      GlassCard(
                        child: Column(
                          children: [
                            const Text('🎯', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              goal.name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Target Tenggat: ${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Progress Indicators
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: CircularProgressIndicator(
                                    value: goal.progress,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.08,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF00BFA5),
                                        ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${goal.percent.toStringAsFixed(0)}%',
                                      style: GoogleFonts.outfit(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      goal.isCompleted
                                          ? 'Tercapai!'
                                          : 'Terkumpul',
                                      style: const TextStyle(
                                        color: Color(0xFF00BFA5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Values display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'TERKUMPUL',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatIDR(goal.currentSavings),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.white10,
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'TARGET HARGA',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatIDR(goal.targetPrice),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            if (!goal.isCompleted) ...[
                              const Divider(color: Colors.white10, height: 32),
                              Text(
                                'Kekurangan dana: ${_formatIDR(remainingClamped)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ADD SAVINGS INPUT CARD
                      if (!goal.isCompleted)
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Tambah Tabungan Baru 💰',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GlassTextField(
                                controller: _savingsController,
                                labelText: 'Jumlah Uang (IDR)',
                                hintText: '1000000',
                                prefixIcon: Icons.add_card,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 20),
                              GlassButton(
                                onPressed: () => _addSavings(finance),
                                child: Text(
                                  'TAMBAH TABUNGAN',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        GlassCard(
                          backgroundColor: const Color(0x2B00E676),
                          borderColor: const Color(0x6600E676),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.stars,
                                color: Colors.greenAccent,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Impian Tercapai!',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Selamat, target dana impian Anda telah terkumpul sepenuhnya. Lanjutkan pencapaian target berikutnya!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
