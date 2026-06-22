import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/finance_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/transaction_model.dart';
import '../widgets/glassmorphism_widgets.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedCategory = 'Makanan';
  String _filterCategory = 'Semua Kategori';
  String _filterTime = 'Semua Waktu';

  final List<String> _categories = const ['Makanan', 'Transportasi', 'Gaya Hidup', 'Hiburan', 'Dana Darurat'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _searchController.dispose();
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

  void _submitTransaction(FinanceController finance) async {
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    final note = _noteController.text.trim();

    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah uang yang valid'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    await finance.addTransaction(amt, _selectedCategory, note);
    _amountController.clear();
    _noteController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi ${_formatIDR(amt)} berhasil dicatat!'),
          backgroundColor: const Color(0xFF00BFA5),
        ),
      );
    }
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> rawList) {
    return rawList.where((t) {
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final noteMatch = t.note.toLowerCase().contains(query);
        final amountMatch = t.amount.toString().contains(query);
        final categoryMatch = t.category.toLowerCase().contains(query);
        if (!noteMatch && !amountMatch && !categoryMatch) return false;
      }

      if (_filterCategory != 'Semua Kategori') {
        if (t.category != _filterCategory) return false;
      }

      if (_filterTime != 'Semua Waktu') {
        final now = DateTime.now();
        if (_filterTime == 'Hari Ini') {
          final today = DateTime(now.year, now.month, now.day);
          final transDate = DateTime(t.date.year, t.date.month, t.date.day);
          if (transDate != today) return false;
        } else if (_filterTime == 'Minggu Ini') {
          final oneWeekAgo = now.subtract(const Duration(days: 7));
          if (t.date.isBefore(oneWeekAgo)) return false;
        } else if (_filterTime == 'Bulan Ini') {
          if (t.date.month != now.month || t.date.year != now.year) return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildFilterSection({
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
    required Color fillColor,
    required Color enabledBorderColor,
    required bool isWide,
  }) {
    final searchField = GlassTextField(
      controller: _searchController,
      labelText: 'Cari transaksi...',
      prefixIcon: Icons.search,
    );

    final categoryDropdown = DropdownButtonFormField<String>(
      value: _filterCategory,
      dropdownColor: isDark ? const Color(0xFF003025) : Colors.white,
      style: TextStyle(color: textColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: 'Kategori',
        labelStyle: TextStyle(color: subtextColor, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: enabledBorderColor),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF00BFA5)),
          borderRadius: BorderRadius.circular(15),
        ),
        filled: true,
        fillColor: fillColor,
      ),
      items: const [
        DropdownMenuItem(value: 'Semua Kategori', child: Text('Semua Kategori')),
        DropdownMenuItem(value: 'Makanan', child: Text('Makanan')),
        DropdownMenuItem(value: 'Transportasi', child: Text('Transportasi')),
        DropdownMenuItem(value: 'Gaya Hidup', child: Text('Gaya Hidup')),
        DropdownMenuItem(value: 'Hiburan', child: Text('Hiburan')),
        DropdownMenuItem(value: 'Dana Darurat', child: Text('Dana Darurat')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _filterCategory = val;
          });
        }
      },
    );

    final timeDropdown = DropdownButtonFormField<String>(
      value: _filterTime,
      dropdownColor: isDark ? const Color(0xFF003025) : Colors.white,
      style: TextStyle(color: textColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: 'Rentang Waktu',
        labelStyle: TextStyle(color: subtextColor, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: enabledBorderColor),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF00BFA5)),
          borderRadius: BorderRadius.circular(15),
        ),
        filled: true,
        fillColor: fillColor,
      ),
      items: const [
        DropdownMenuItem(value: 'Semua Waktu', child: Text('Semua Waktu')),
        DropdownMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
        DropdownMenuItem(value: 'Minggu Ini', child: Text('Minggu Ini')),
        DropdownMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _filterTime = val;
          });
        }
      },
    );

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Expanded(flex: 2, child: searchField),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: categoryDropdown),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: timeDropdown),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          children: [
            searchField,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: categoryDropdown),
                const SizedBox(width: 12),
                Expanded(child: timeDropdown),
              ],
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceController>(context);
    final themeNotifier = Provider.of<ThemeController>(context);
    final isDark = themeNotifier.isDarkMode;

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF546E7A);
    final subtextColor54 = isDark ? Colors.white54 : const Color(0x8A546E7A);
    final fillColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.45);
    final enabledBorderColor = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12);
    final expenseTextColor = isDark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F);
    final dividerColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    final filteredTrans = _getFilteredTransactions(finance.transactions);

    final double width = MediaQuery.of(context).size.width;
    final bool isWide = width >= 720;

    if (!isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ADD TRANSACTION CARD FORM
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Catat Pengeluaran Baru 💸',
                    style: GoogleFonts.outfit(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Amount field
                  GlassTextField(
                    controller: _amountController,
                    labelText: 'Jumlah Uang (IDR)',
                    hintText: '50000',
                    prefixIcon: Icons.money,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  // Category select
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: isDark ? const Color(0xFF003025) : Colors.white,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Kategori Pos',
                      labelStyle: TextStyle(color: subtextColor),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: enabledBorderColor),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF00BFA5)),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: fillColor,
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Notes field
                  GlassTextField(
                    controller: _noteController,
                    labelText: 'Catatan / Keterangan',
                    hintText: 'Makan soto ayam',
                    prefixIcon: Icons.edit_note,
                  ),
                  const SizedBox(height: 16),

                  // Add button
                  GlassButton(
                    onPressed: () => _submitTransaction(finance),
                    child: Text(
                      'CATAT TRANSAKSI',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. TRANSACTION HISTORY TITLE
            Text(
              'Riwayat Pengeluaran Harian',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 12),

            // 3. FILTER CONTROLS
            _buildFilterSection(
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
              fillColor: fillColor,
              enabledBorderColor: enabledBorderColor,
              isWide: false,
            ),

            // Transaction list
            if (filteredTrans.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'Belum ada transaksi pengeluaran.',
                    style: GoogleFonts.inter(color: subtextColor54, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTrans.length,
                separatorBuilder: (_, __) => Divider(color: dividerColor, height: 1),
                itemBuilder: (context, index) {
                  final trans = filteredTrans[index];
                  IconData catIcon;
                  Color catColor;

                  switch (trans.category) {
                    case 'Makanan':
                      catIcon = Icons.fastfood_outlined;
                      catColor = const Color(0xFF00BFA5);
                      break;
                    case 'Transportasi':
                      catIcon = Icons.directions_car_outlined;
                      catColor = const Color(0xFF29B6F6);
                      break;
                    case 'Gaya Hidup':
                      catIcon = Icons.shopping_bag_outlined;
                      catColor = const Color(0xFFEC407A);
                      break;
                    case 'Hiburan':
                      catIcon = Icons.confirmation_number_outlined;
                      catColor = const Color(0xFFFFA726);
                      break;
                    case 'Dana Darurat':
                      catIcon = Icons.health_and_safety_outlined;
                      catColor = const Color(0xFFEF5350);
                      break;
                    default:
                      catIcon = Icons.attach_money;
                      catColor = Colors.white54;
                  }

                  return Dismissible(
                    key: Key(trans.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) async {
                      await finance.deleteTransaction(trans.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaksi berhasil dihapus')),
                        );
                      }
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: catColor.withOpacity(0.15),
                        child: Icon(catIcon, color: catColor, size: 20),
                      ),
                      title: Text(
                        trans.note.isNotEmpty ? trans.note : trans.category,
                        style: GoogleFonts.inter(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${trans.date.day}/${trans.date.month}/${trans.date.year} - ${trans.category}',
                        style: TextStyle(color: subtextColor54, fontSize: 11),
                      ),
                      trailing: Text(
                        '- ${_formatIDR(trans.amount)}',
                        style: GoogleFonts.outfit(
                          color: expenseTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      );
    } else {
      // Wide layout (side-by-side)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Add Transaction Form (fixed width)
            SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Catat Pengeluaran Baru 💸',
                        style: GoogleFonts.outfit(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      GlassTextField(
                        controller: _amountController,
                        labelText: 'Jumlah Uang (IDR)',
                        hintText: '50000',
                        prefixIcon: Icons.money,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: isDark ? const Color(0xFF003025) : Colors.white,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Kategori Pos',
                          labelStyle: TextStyle(color: subtextColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: enabledBorderColor),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF00BFA5)),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: fillColor,
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        controller: _noteController,
                        labelText: 'Catatan / Keterangan',
                        hintText: 'Makan soto ayam',
                        prefixIcon: Icons.edit_note,
                      ),
                      const SizedBox(height: 16),
                      GlassButton(
                        onPressed: () => _submitTransaction(finance),
                        child: Text(
                          'CATAT TRANSAKSI',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Right: Transaction History List (scrollable)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Riwayat Pengeluaran Harian',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),

                  // Filter controls
                  _buildFilterSection(
                    isDark: isDark,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    fillColor: fillColor,
                    enabledBorderColor: enabledBorderColor,
                    isWide: true,
                  ),

                  Expanded(
                    child: filteredTrans.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada transaksi pengeluaran.',
                              style: GoogleFonts.inter(color: subtextColor54, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredTrans.length,
                            separatorBuilder: (_, __) => Divider(color: dividerColor, height: 1),
                            itemBuilder: (context, index) {
                              final trans = filteredTrans[index];
                              IconData catIcon;
                              Color catColor;

                              switch (trans.category) {
                                case 'Makanan':
                                  catIcon = Icons.fastfood_outlined;
                                  catColor = const Color(0xFF00BFA5);
                                  break;
                                case 'Transportasi':
                                  catIcon = Icons.directions_car_outlined;
                                  catColor = const Color(0xFF29B6F6);
                                  break;
                                case 'Gaya Hidup':
                                  catIcon = Icons.shopping_bag_outlined;
                                  catColor = const Color(0xFFEC407A);
                                  break;
                                case 'Hiburan':
                                  catIcon = Icons.confirmation_number_outlined;
                                  catColor = const Color(0xFFFFA726);
                                  break;
                                case 'Dana Darurat':
                                  catIcon = Icons.health_and_safety_outlined;
                                  catColor = const Color(0xFFEF5350);
                                  break;
                                default:
                                  catIcon = Icons.attach_money;
                                  catColor = Colors.white54;
                              }

                              return Dismissible(
                                key: Key(trans.id),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) async {
                                  await finance.deleteTransaction(trans.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Transaksi berhasil dihapus')),
                                    );
                                  }
                                },
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: catColor.withOpacity(0.15),
                                    child: Icon(catIcon, color: catColor, size: 20),
                                  ),
                                  title: Text(
                                    trans.note.isNotEmpty ? trans.note : trans.category,
                                    style: GoogleFonts.inter(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${trans.date.day}/${trans.date.month}/${trans.date.year} - ${trans.category}',
                                    style: TextStyle(color: subtextColor54, fontSize: 11),
                                  ),
                                  trailing: Text(
                                    '- ${_formatIDR(trans.amount)}',
                                    style: GoogleFonts.outfit(
                                      color: expenseTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
