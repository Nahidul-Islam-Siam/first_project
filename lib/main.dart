import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/brand_colors.dart';
import 'app/app_globals.dart';
import 'app/app_routes.dart';
import 'app/route_names.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noorify',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: BrandColors.primary,
        scaffoldBackgroundColor: BrandColors.screenBackground,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      initialRoute: RouteNames.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
