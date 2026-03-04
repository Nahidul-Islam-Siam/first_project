import 'package:flutter/material.dart';

import '../app/route_names.dart';

class UiPreviewHome extends StatelessWidget {
  const UiPreviewHome({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <({String title, String routeName})>[
      (title: 'Splash Screen', routeName: RouteNames.splash),
      (title: 'Sign Up Screen', routeName: RouteNames.signUp),
      (title: 'Profile Preferences', routeName: RouteNames.preferences),
      (title: 'Edit Profile', routeName: RouteNames.editProfile),
      (title: 'Daily Activity', routeName: RouteNames.activity),
      (title: 'Quran Screen', routeName: RouteNames.quran),
      (title: 'Privacy Policy', routeName: RouteNames.privacyPolicy),
      (title: 'About & Version', routeName: RouteNames.about),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('UI Mock Screens')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return FilledButton.tonal(
            onPressed: () => Navigator.of(context).pushNamed(item.routeName),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(item.title),
          );
        },
      ),
    );
  }
}
