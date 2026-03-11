import 'dart:async';

import 'package:flutter/material.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/auth/services/auth_service.dart';
import 'package:first_project/shared/services/app_globals.dart';

class RamadanSplashScreen extends StatefulWidget {
  const RamadanSplashScreen({super.key});

  @override
  State<RamadanSplashScreen> createState() => _RamadanSplashScreenState();
}

class _RamadanSplashScreenState extends State<RamadanSplashScreen> {
  static const _splashDuration = Duration(milliseconds: 1800);
  static const _openingImagePath = 'assets/images/app-opening-page.jpg';

  @override
  void initState() {
    super.initState();
    _openHomeAfterDelay();
  }

  Future<void> _openHomeAfterDelay() async {
    await Future<void>.delayed(_splashDuration);
    if (!mounted) return;
    var nextRoute = RouteNames.home;
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await AuthService.instance.syncLocalProfileFromCurrentUser();
      }
      nextRoute = skipAuthGateNotifier.value || user != null
          ? RouteNames.home
          : RouteNames.signIn;
    } catch (_) {
      nextRoute = RouteNames.home;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          _openingImagePath,
          key: const Key('opening_splash_image'),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Noorify',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
