import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class NoorifyGlassTheme {
  NoorifyGlassTheme(this.context);

  final BuildContext context;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bgTop => isDark ? const Color(0xFF060C17) : const Color(0xFFF7FBFF);
  Color get bgMid => isDark ? const Color(0xFF0A1521) : const Color(0xFFEAF4FB);
  Color get bgBottom =>
      isDark ? const Color(0xFF08111B) : const Color(0xFFF2F8FD);

  Color get glassStart =>
      isDark ? const Color(0xFF121F2E) : const Color(0xF7FFFFFF);
  Color get glassEnd =>
      isDark ? const Color(0xFF0D1824) : const Color(0xDBF2F8FD);
  Color get glassBorder =>
      isDark ? const Color(0x22D2F4FF) : const Color(0xCCD1E1EC);
  Color get glassShadow =>
      isDark ? const Color(0x50000000) : const Color(0x260E3853);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF143349);
  Color get textSecondary =>
      isDark ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94);
  Color get textMuted =>
      isDark ? const Color(0xFF88AFC7) : const Color(0xFF4D6B82);

  Color get accent =>
      isDark ? const Color(0xFF2EB8E6) : const Color(0xFF1EA8B8);
  Color get accentSoft =>
      isDark ? const Color(0xFF94D5F5) : const Color(0xFF2EA2BF);
}

class NoorifyGlassBackground extends StatelessWidget {
  const NoorifyGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [glass.bgTop, glass.bgMid, glass.bgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -130,
            left: -90,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x3332B8E6), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x2230A4CF), Color(0x00000000)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class NoorifyGlassCard extends StatelessWidget {
  const NoorifyGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = const BorderRadius.all(Radius.circular(18)),
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: [glass.glassStart, glass.glassEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: glass.glassBorder),
            boxShadow:
                boxShadow ??
                [
                  BoxShadow(
                    color: glass.glassShadow,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}
