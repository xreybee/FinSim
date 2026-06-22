import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../widgets/glassmorphism_widgets.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final success = await authController.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authController.errorMessage ?? 'Gagal masuk. Silakan coba lagi.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
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

    // Responsive sizing
    final bool isSmallPhone = screenHeight < 640;
    final bool isDesktop = screenWidth >= 900;
    final bool isTablet = screenWidth >= 600 && screenWidth < 900;
    final double maxCardWidth = isDesktop ? 420 : (isTablet ? 400 : 500);
    final double logoSize = isSmallPhone ? 36 : (isDesktop ? 52 : 44);
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
                      // Logo/Title Section
                      Center(
                        child: Text(
                          'finsim',
                          style: GoogleFonts.outfit(
                            fontSize: logoSize,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00BFA5).withOpacity(isDark ? 0.4 : 0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallPhone ? 4 : 8),
                      Center(
                        child: Text(
                          'Smart Financial Advisor',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isSmallPhone ? 12 : 14,
                            fontWeight: FontWeight.w400,
                            color: subColor,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallPhone ? 24 : 40),

                      // Theme toggle row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                              color: isDark ? Colors.amberAccent : const Color(0xFF546E7A),
                              size: 22,
                            ),
                            onPressed: () => themeCtrl.toggleTheme(),
                            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Login Card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Masuk ke Akun Anda',
                              style: GoogleFonts.outfit(
                                fontSize: isSmallPhone ? 18 : 22,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: isSmallPhone ? 16 : 24),

                            // Email Input
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

                            // Password Input
                            GlassTextField(
                              controller: _passwordController,
                              labelText: 'Password',
                              hintText: '******',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: subColor,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Password wajib diisi';
                                if (val.length < 6)
                                  return 'Password minimal 6 karakter';
                                return null;
                              },
                            ),
                            SizedBox(height: isSmallPhone ? 16 : 24),

                            // Login Button
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
                                          'MASUK',
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
                      SizedBox(height: isSmallPhone ? 16 : 24),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(color: subColor, fontSize: isSmallPhone ? 12 : 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                color: const Color(0xFF00BFA5),
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallPhone ? 12 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallPhone ? 16 : 32),

                      // Developer/Sandbox Shortcut
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Provider.of<AuthController>(
                              context,
                              listen: false,
                            ).enableMockMode();
                          },
                          icon: Icon(
                            Icons.developer_board,
                            color: subColor.withOpacity(0.6),
                            size: 16,
                          ),
                          label: Text(
                            'Gunakan Mode Simulasi',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: subColor.withOpacity(0.6),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
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
