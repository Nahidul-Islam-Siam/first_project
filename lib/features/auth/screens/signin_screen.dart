import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  static const _bgPath = 'assets/images/Login.jpg';

  InputDecoration _fieldStyle(
    NoorifyGlassTheme glass, {
    required String label,
    required String hint,
    required IconData suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: glass.textMuted, fontSize: 10),
      hintText: hint,
      hintStyle: TextStyle(
        color: glass.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: glass.isDark
          ? const Color(0x3F122634)
          : const Color(0xDFFFFFFF),
      suffixIcon: Icon(suffix, color: glass.accentSoft, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: glass.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: glass.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: glass.accent.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _authShell(BuildContext context, Widget child) {
    final glass = NoorifyGlassTheme(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _bgPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [glass.bgTop, glass.bgMid, glass.bgBottom],
              ),
            ),
          ),
        ),
        Container(
          color: Colors.black.withValues(alpha: glass.isDark ? 0.45 : 0.2),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(color: Colors.transparent),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orDivider(NoorifyGlassTheme glass) {
    return Row(
      children: [
        Expanded(child: Divider(color: glass.glassBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: TextStyle(
              color: glass.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: glass.glassBorder)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    void openHome() {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
    }

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: _authShell(
        context,
        NoorifyGlassCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          radius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: glass.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Center(
                child: SizedBox(
                  width: 80,
                  child: Divider(
                    color: glass.accent.withValues(alpha: 0.5),
                    thickness: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: _fieldStyle(
                  glass,
                  label: 'Email',
                  hint: 'muslimah.gmail.com',
                  suffix: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                decoration: _fieldStyle(
                  glass,
                  label: 'Password',
                  hint: '........',
                  suffix: Icons.visibility_off_outlined,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Forgot password flow coming soon'),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: glass.accentSoft,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 42,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: glass.accent,
                    foregroundColor: glass.isDark
                        ? const Color(0xFF072734)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: openHome,
                  child: const Text(
                    'SIGN IN',
                    style: TextStyle(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _orDivider(glass),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: FilledButton.tonalIcon(
                  onPressed: openHome,
                  icon: const Icon(Icons.g_mobiledata, size: 20),
                  label: const Text('Continue With Google'),
                  style: FilledButton.styleFrom(
                    foregroundColor: glass.textPrimary,
                    backgroundColor: glass.isDark
                        ? const Color(0x332EB8E6)
                        : const Color(0x221EA8B8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have any account? ",
                    style: TextStyle(color: glass.textSecondary, fontSize: 12),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteNames.signUp),
                    child: Text(
                      'Register',
                      style: TextStyle(
                        color: glass.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
