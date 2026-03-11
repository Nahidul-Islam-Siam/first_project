import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:first_project/firebase_options.dart';

import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/services/push_notification_service.dart';
import 'package:first_project/core/constants/app_routes.dart';
import 'package:first_project/core/constants/route_names.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeNotifications();
  await loadAppPreferences();
  runApp(const MyApp());
  unawaited(initializePushNotifications());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        darkThemeEnabledNotifier,
        appFontSizeNotifier,
      ]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Noorify',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: BrandColors.primary,
            scaffoldBackgroundColor: BrandColors.screenBackground,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: BrandColors.primary,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme,
            ),
          ),
          themeMode: darkThemeEnabledNotifier.value
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final textScale = appFontScale(appFontSizeNotifier.value);
            return MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(textScale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: RouteNames.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
