import 'package:flutter/material.dart';

import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/core/constants/route_names.dart';

Widget bottomNav(BuildContext context, int active) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final activeColor = isDark ? const Color(0xFF27D8B2) : BrandColors.primary;
  final inactiveColor = isDark
      ? const Color(0xFF8FA7B3)
      : const Color(0xFF7E93A0);

  final items = <({String label, IconData icon, String routeName})>[
    (label: 'Home', icon: Icons.home_filled, routeName: RouteNames.activity),
    (
      label: 'Discover',
      icon: Icons.explore_outlined,
      routeName: RouteNames.asma,
    ),
    (
      label: 'Quran',
      icon: Icons.menu_book_outlined,
      routeName: RouteNames.quran,
    ),
    (
      label: 'Prayer',
      icon: Icons.calendar_month_outlined,
      routeName: RouteNames.prayerCompass,
    ),
    (
      label: 'Profile',
      icon: Icons.person_outline,
      routeName: RouteNames.preferences,
    ),
  ];

  void onTapItem(int index) {
    final routeName = items[index].routeName;
    if (index == active) return;
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  return Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xE9112028) : const Color(0xEEFFFFFF),
      border: Border(
        top: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFD4E6E1),
        ),
      ),
    ),
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
                  color: isActive ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? activeColor : inactiveColor,
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
