import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../widgets/glassmorphism_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final success = await authController.signUp(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi Berhasil! Silakan masuk.'),
            backgroundColor: Color(0xFF00BFA5),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authController.errorMessage ?? 'Gagal melakukan registrasi.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Provider.of<ThemeController>(context);
    final isDark = themeCtrl.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xB3FFFFFF) : const Color(0xFF78909C);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool isSmallPhone = screenHeight < 640;
    final bool isDesktop = screenWidth >= 900;
    final bool isTablet = screenWidth >= 600 && screenWidth < 900;
    final double maxCardWidth = isDesktop ? 420 : (isTablet ? 400 : 500);
    final double horizontalPad = isDesktop ? 48 : (isTablet ? 36 : 24);

    return Scaffold(
      body: BubbleBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: isSmallPhone ? 12 : 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: textColor),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Text(
                            'Kembali',
                            style: GoogleFonts.inter(color: textColor, fontSize: 16),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallPhone ? 12 : 24),
                      Center(
                        child: Text(
                          'Buat Akun Baru',
                          style: GoogleFonts.outfit(
                            fontSize: isSmallPhone ? 24 : 32,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallPhone ? 4 : 8),
                      Center(
                        child: Text(
                          'Mulai kelola alokasi pos keuangan cerdas Anda hari ini',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isSmallPhone ? 12 : 14,
                            fontWeight: FontWeight.w400,
                            color: subColor,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallPhone ? 20 : 32),

                      // Registration Form Card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Field
                            GlassTextField(
                              controller: _emailController,
                              labelText: 'Alamat Email',
                              hintText: 'nama@email.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Email wajib diisi';
                                if (!val.contains('@'))
                                  return 'Format email tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            GlassTextField(
                              controller: _passwordController,
                              labelText: 'Password',
                              hintText: 'Min. 6 karakter',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePass,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: subColor,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Password wajib diisi';
                                if (val.length < 6)
                                  return 'Password minimal 6 karakter';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            GlassTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Konfirmasi Password',
                              hintText: '******',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscureConfirm,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: subColor,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Konfirmasi password wajib diisi';
                                if (val != _passwordController.text)
                                  return 'Password tidak cocok';
                                return null;
                              },
                            ),
                            SizedBox(height: isSmallPhone ? 16 : 24),

                            // Register Submit Button
                            Consumer<AuthController>(
                              builder: (context, authState, child) {
                                return authState.isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF00BFA5),
                                        ),
                                      )
                                    : GlassButton(
                                        onPressed: _submit,
                                        child: Text(
                                          'DAFTAR SEKARANG',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallPhone ? 16 : 32),
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
