import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/core/utils/network_utils.dart';
import 'package:first_project/features/auth/services/auth_service.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _bgPath = 'assets/images/Login.jpg';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _saveInfo = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldStyle(
    NoorifyGlassTheme glass, {
    required String label,
    required String hint,
    required Widget suffixIcon,
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
      suffixIcon: suffixIcon,
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _ensureInternetOrShowMessage() async {
    final online = await NetworkUtils.hasInternet();
    if (!online) {
      _showMessage(
        'No internet connection. Please check network and try again.',
      );
      return false;
    }
    return true;
  }

  Future<void> _setSkipAuthGate(bool value) async {
    skipAuthGateNotifier.value = value;
    await saveAppPreferences();
  }

  Future<void> _continueWithoutSignIn() async {
    await _setSkipAuthGate(true);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
  }

  Future<void> _signUp() async {
    if (!await _ensureInternetOrShowMessage()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMessage('Please complete all fields.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    if (password != confirm) {
      _showMessage('Password and confirm password do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
      );
      await _setSkipAuthGate(false);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
    } on FirebaseAuthException catch (e) {
      _showMessage(AuthService.instance.messageForException(e));
    } catch (_) {
      _showMessage('Sign up failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!await _ensureInternetOrShowMessage()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      await _setSkipAuthGate(false);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
    } on GoogleSignInException catch (e) {
      _showMessage(AuthService.instance.messageForGoogleException(e));
    } on FirebaseAuthException catch (e) {
      _showMessage(AuthService.instance.messageForException(e));
    } catch (_) {
      _showMessage('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

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
                'Sign Up',
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: _fieldStyle(
                  glass,
                  label: 'Email',
                  hint: 'muslimah.gmail.com',
                  suffixIcon: Icon(
                    Icons.email_outlined,
                    color: glass.accentSoft,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: _fieldStyle(
                  glass,
                  label: 'Password',
                  hint: '........',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: glass.accentSoft,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_isLoading) return;
                  _signUp();
                },
                autofillHints: const [AutofillHints.newPassword],
                decoration: _fieldStyle(
                  glass,
                  label: 'Confirm Password',
                  hint: '........',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: glass.accentSoft,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Switch.adaptive(
                    value: _saveInfo,
                    onChanged: (v) => setState(() => _saveInfo = v),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Save my info?',
                    style: TextStyle(
                      color: glass.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: glass.isDark
                                ? const Color(0xFF072734)
                                : Colors.white,
                          ),
                        )
                      : const Text(
                          'SIGN UP',
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
                  onPressed: () =>
                      _showMessage('Phone sign-up will be added next.'),
                  icon: const Icon(Icons.phone_android, size: 18),
                  label: const Text('Continue With Phone'),
                  style: FilledButton.styleFrom(
                    foregroundColor: glass.textPrimary,
                    backgroundColor: glass.isDark
                        ? const Color(0x332EB8E6)
                        : const Color(0x221EA8B8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: FilledButton.tonalIcon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 20),
                  label: Text(
                    _isLoading ? 'Please wait...' : 'Continue With Google',
                  ),
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
                    'Already have an account? ',
                    style: TextStyle(color: glass.textSecondary, fontSize: 12),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteNames.signIn),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: glass.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading ? null : _continueWithoutSignIn,
                child: const Text(
                  'Skip for now',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
