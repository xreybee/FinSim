import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/finance_controller.dart';
import '../controllers/theme_controller.dart';
import 'widgets/glassmorphism_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _professionController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();

  String _photoUrl = '';
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final finance = Provider.of<FinanceController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    _nameController = TextEditingController(text: finance.userProfile?.name ?? '');
    _professionController = TextEditingController(text: finance.userProfile?.profession ?? '');
    _emailController = TextEditingController(text: auth.currentUserEmail ?? '');
    _photoUrl = finance.userProfile?.photoUrl ?? '';

    _nameController.addListener(() {
      setState(() {});
    });
    _professionController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 60);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        setState(() {
          _photoUrl = 'data:image/png;base64,$base64Str';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final auth = Provider.of<AuthController>(context, listen: false);
    final finance = Provider.of<FinanceController>(context, listen: false);

    final newName = _nameController.text.trim();
    final newProfession = _professionController.text.trim();
    final newEmail = _emailController.text.trim();
    final newPassword = _passwordController.text.trim();

    try {
      // 1. Update personal details in Firestore/Mock
      await finance.updatePersonalProfile(newName, _photoUrl, newProfession);

      // 3. Update credentials in Auth (email & password)
      if (newEmail.isNotEmpty || newPassword.isNotEmpty) {
        final success = await auth.updateCredentials(newEmail, newPassword);
        if (!success) {
          throw Exception(auth.errorMessage ?? 'Gagal memperbarui kredensial login');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui! 🎉'),
            backgroundColor: Color(0xFF00BFA5),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _exportBackup(FinanceController finance) {
    try {
      final userProfile = finance.userProfile;
      final goals = finance.goals;
      final transactions = finance.transactions;

      final backupMap = {
        'version': 1,
        'profile': userProfile?.toMap() ?? {},
        'goals': goals.map((g) => {
          'id': g.id,
          'userId': g.userId,
          'name': g.name,
          'targetPrice': g.targetPrice,
          'currentSavings': g.currentSavings,
          'deadline': g.deadline.toIso8601String(),
        }).toList(),
        'transactions': transactions.map((t) => {
          'id': t.id,
          'userId': t.userId,
          'amount': t.amount,
          'category': t.category,
          'note': t.note,
          'date': t.date.toIso8601String(),
        }).toList(),
      };

      final jsonStr = jsonEncode(backupMap);
      Clipboard.setData(ClipboardData(text: jsonStr));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data cadangan berhasil disalin ke clipboard! 📋'),
          backgroundColor: Color(0xFF00BFA5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat cadangan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showRestoreDialog(BuildContext context, FinanceController finance) {
    final textController = TextEditingController();
    final themeNotifier = Provider.of<ThemeController>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final dialogBg = isDark ? const Color(0xFF00251A) : Colors.white;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Pulihkan Data Dari Cadangan',
            style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tempelkan (paste) kode JSON cadangan Anda di bawah ini:',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                style: TextStyle(color: textColor, fontSize: 12),
                decoration: InputDecoration(
                  hintText: '{"version": 1, ...}',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00BFA5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final jsonStr = textController.text.trim();
                if (jsonStr.isEmpty) return;

                Navigator.of(ctx).pop();

                setState(() {
                  _isSaving = true;
                });

                try {
                  await finance.restoreBackup(jsonStr);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data berhasil dipulihkan dari cadangan! 🎉'),
                        backgroundColor: Color(0xFF00BFA5),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal memulihkan cadangan: Kode JSON tidak valid.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSaving = false;
                    });
                  }
                }
              },
              child: const Text('PULIHKAN', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileImage() {
    if (_photoUrl.isEmpty) {
      return Container(
        color: const Color(0xFF003025),
        child: const Icon(Icons.person, size: 70, color: Color(0xFF00BFA5)),
      );
    }
    if (_photoUrl.startsWith('data:image/')) {
      final base64Str = _photoUrl.split(',').last;
      try {
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF003025),
            child: const Icon(Icons.person, size: 70, color: Color(0xFF00BFA5)),
          ),
        );
      } catch (e) {
        // Fallback below
      }
    }
    if (kIsWeb || _photoUrl.startsWith('http://') || _photoUrl.startsWith('https://') || _photoUrl.startsWith('blob:')) {
      return Image.network(
        _photoUrl,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF003025),
          child: const Icon(Icons.person, size: 70, color: Color(0xFF00BFA5)),
        ),
      );
    }
    final file = File(_photoUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    }
    return Container(
      color: const Color(0xFF003025),
      child: const Icon(Icons.person, size: 70, color: Color(0xFF00BFA5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeController>(context);
    final isDark = themeNotifier.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white70 : const Color(0xFF546E7A);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Profil Pribadi 👤',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: BubbleBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Photo Header Section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF00BFA5), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00BFA5).withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _buildProfileImage(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00BFA5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _nameController.text.isNotEmpty ? _nameController.text : 'Finsimer',
                          style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Center(
                        child: Text(
                          _professionController.text.isNotEmpty ? _professionController.text : 'Perencana Keuangan',
                          style: GoogleFonts.inter(color: subColor, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Profile Details Form Card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Edit Detail Profil',
                              style: GoogleFonts.outfit(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            // Name Field
                            GlassTextField(
                              controller: _nameController,
                              labelText: 'Nama Lengkap',
                              hintText: 'Reyhan FinSim',
                              prefixIcon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),

                            // Profession Field
                            GlassTextField(
                              controller: _professionController,
                              labelText: 'Profesi',
                              hintText: 'Software Engineer',
                              prefixIcon: Icons.work_outline,
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            GlassTextField(
                              controller: _emailController,
                              labelText: 'Alamat Email',
                              hintText: 'reyhan@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            GlassTextField(
                              controller: _passwordController,
                              labelText: 'Password Baru (Opsional)',
                              hintText: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                            ),
                            const SizedBox(height: 24),

                            // Save Button
                            _isSaving
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                                    ),
                                  )
                                : GlassButton(
                                    onPressed: _saveProfile,
                                    child: Text(
                                      'SIMPAN PERUBAHAN',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ========== BACKUP & RESTORE ==========
                      Builder(
                        builder: (context) {
                          final finance = Provider.of<FinanceController>(context, listen: false);
                          final themeCtrl = Provider.of<ThemeController>(context);
                          final isDark = themeCtrl.isDarkMode;
                          final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
                          final subColor = isDark ? Colors.white70 : const Color(0xFF546E7A);
                          return GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.cloud_sync_outlined, color: Color(0xFF00BFA5), size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Cadangkan & Pulihkan Data',
                                        style: GoogleFonts.outfit(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ekspor seluruh data Anda sebagai JSON ke clipboard, atau pulihkan dari cadangan.',
                                  style: GoogleFonts.inter(color: subColor, fontSize: 11),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GlassButton(
                                        onPressed: () => _exportBackup(finance),
                                        color: const Color(0xFF00BFA5),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.file_upload_outlined, size: 18, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text(
                                              'EKSPOR',
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GlassButton(
                                        onPressed: () => _showRestoreDialog(context, finance),
                                        color: const Color(0xFF0288D1),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.file_download_outlined, size: 18, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text(
                                              'PULIHKAN',
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
