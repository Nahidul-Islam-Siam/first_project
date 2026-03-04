import 'package:flutter/material.dart';

import '../app/route_names.dart';

Widget bottomNav(BuildContext context, int active) {
  final items = <({String label, IconData icon, String? routeName})>[
    (label: 'Home', icon: Icons.home_filled, routeName: RouteNames.activity),
    (label: 'Discover', icon: Icons.explore_outlined, routeName: null),
    (
      label: 'Quran',
      icon: Icons.menu_book_outlined,
      routeName: RouteNames.quran,
    ),
    (
      label: 'Prayer',
      icon: Icons.calendar_month_outlined,
      routeName: RouteNames.activity,
    ),
    (
      label: 'Profile',
      icon: Icons.person_outline,
      routeName: RouteNames.preferences,
    ),
  ];

  void onTapItem(int index) {
    final routeName = items[index].routeName;
    if (routeName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This page is coming soon')));
      return;
    }

    if (index == active) return;
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  return Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isActive = index == active;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTapItem(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isActive ? const Color(0xFF14A3B8) : Colors.black45,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? const Color(0xFF14A3B8) : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ),
  );
}
