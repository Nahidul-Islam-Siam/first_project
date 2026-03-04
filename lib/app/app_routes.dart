import 'package:flutter/material.dart';

import 'route_names.dart';
import '../screens/daily_activity_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/profile_preferences_screen.dart';
import '../screens/quran_screen.dart';
import '../screens/ramadan_splash_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/ui_preview_home.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.preview:
        return _page(const UiPreviewHome(), settings);
      case RouteNames.splash:
        return _page(const RamadanSplashScreen(), settings);
      case RouteNames.signUp:
        return _page(const SignupScreen(), settings);
      case RouteNames.preferences:
        return _page(const ProfilePreferencesScreen(), settings);
      case RouteNames.editProfile:
        return _page(const EditProfileScreen(), settings);
      case RouteNames.activity:
        return _page(const DailyActivityScreen(), settings);
      case RouteNames.quran:
        return _page(const QuranScreen(), settings);
      default:
        return _page(const UiPreviewHome(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(
    Widget child,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<void>(builder: (_) => child, settings: settings);
  }
}
