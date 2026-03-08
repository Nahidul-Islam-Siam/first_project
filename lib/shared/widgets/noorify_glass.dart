import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class NoorifyGlassTheme {
  NoorifyGlassTheme(this.context);

  final BuildContext context;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bgTop =>
      isDark ? const Color(0xFF071A1F) : const Color(0xFFF4FBFA);
  Color get bgMid =>
      isDark ? const Color(0xFF0A2229) : const Color(0xFFEAF6F3);
  Color get bgBottom =>
      isDark ? const Color(0xFF08161C) : const Color(0xFFF3FBFA);

  Color get glassStart =>
      isDark ? const Color(0xCC14252B) : const Color(0xF2FFFFFF);
  Color get glassEnd =>
      isDark ? const Color(0xB0122027) : const Color(0xDBEDF7F5);
  Color get glassBorder =>
      isDark ? const Color(0x44A7F5DB) : const Color(0xFFD3E8E2);
  Color get glassShadow =>
      isDark ? const Color(0x66000000) : const Color(0x1A154D41);

  Color get textPrimary =>
      isDark ? const Color(0xFFEAF8F3) : const Color(0xFF153430);
  Color get textSecondary =>
      isDark ? const Color(0xFF98B9B0) : const Color(0xFF4D756D);
  Color get textMuted =>
      isDark ? const Color(0xFF7FA097) : const Color(0xFF64887F);

  Color get accent => isDark ? const Color(0xFF27D8B2) : const Color(0xFF119C88);
  Color get accentSoft =>
      isDark ? const Color(0xFF7EE4CD) : const Color(0xFF23B09A);
}

class NoorifyGlassBackground extends StatelessWidget {
  const NoorifyGlassBackground({
    super.key,
    required this.child,
  });

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
                  colors: [Color(0x3327D8B2), Color(0x00000000)],
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
                  colors: [Color(0x2227D8B2), Color(0x00000000)],
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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;

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
            boxShadow: [
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
