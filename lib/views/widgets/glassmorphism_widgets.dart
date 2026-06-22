import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/theme_controller.dart';

/// A premium dark teal or light pastel gradient background decorated with blurred, semi-transparent bubbles.
class BubbleBackground extends StatelessWidget {
  final Widget child;

  const BubbleBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeController>(context);
    final isDark = themeNotifier.isDarkMode;

    return Stack(
      children: [
        // 1. Theme-based Gradient Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF004D40), // Dark Teal
                      const Color(0xFF00251A), // Ultra Dark Teal
                    ]
                  : [
                      const Color(0xFFE0F2F1), // Soft Light Teal
                      const Color(0xFFB2DFDB), // Pastel Blue-Teal
                    ],
            ),
          ),
        ),
        // 2. Decorative Blurred Bubbles (Accent colors adjusted for light/dark)
        Positioned(
          top: -50,
          left: -30,
          child: _buildBubble(180, isDark ? const Color(0x3300BFA5) : const Color(0x4D00BFA5)),
        ),
        Positioned(
          bottom: 100,
          right: -80,
          child: _buildBubble(260, isDark ? const Color(0x2600E676) : const Color(0x3D00E676)),
        ),
        Positioned(
          top: 350,
          left: -100,
          child: _buildBubble(220, isDark ? const Color(0x1F00B0FF) : const Color(0x3300B0FF)),
        ),
        Positioned(
          top: 150,
          right: 50,
          child: _buildBubble(120, isDark ? const Color(0x2A1DE9B6) : const Color(0x401DE9B6)),
        ),
        // 3. The actual page content
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _buildBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

/// A container that applies a BackdropFilter blur and a transparent border
/// to achieve a premium frosted-glass card look.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blur = 20.0,
    this.borderColor,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeController>(context);
    final isDark = themeNotifier.isDarkMode;

    final defaultBgStart = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.55);
    final defaultBgEnd = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.white.withOpacity(0.20);

    final defaultBorderColor = isDark
        ? Colors.white.withOpacity(0.18)
        : Colors.white.withOpacity(0.40);

    final shadowColor = isDark
        ? Colors.black.withOpacity(0.15)
        : Colors.black.withOpacity(0.08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor ?? defaultBgStart,
                backgroundColor != null
                    ? backgroundColor!.withOpacity(backgroundColor!.a * 0.4)
                    : defaultBgEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? defaultBorderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: child,
        ),
      ),
    );
  }
}

/// An input field decorated with the glassmorphism aesthetic.
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeController>(context);
    final isDark = themeNotifier.isDarkMode;

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final labelColor = isDark ? const Color(0xB3FFFFFF) : const Color(0xFF546E7A);
    final hintColor = isDark ? const Color(0x66FFFFFF) : const Color(0x99546E7A);
    final fillColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.45);
    final enabledBorderColor = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: labelColor),
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: labelColor)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: enabledBorderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

/// A primary button styled with touch scale animation for the premium dark/teal environment.
class GlassButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final double borderRadius;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.borderRadius = 15.0,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onPressed();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: widget.color != null
                  ? [widget.color!.withOpacity(0.85), widget.color!.withOpacity(0.55)]
                  : [
                      const Color(0xFF00BFA5).withOpacity(0.9), // Teal accent
                      const Color(0xFF0288D1).withOpacity(0.7), // Deep Cyan highlight (premium color harmony)
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.color ?? const Color(0xFF00BFA5)).withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: null, // Tap handled by GestureDetector scale triggers
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
