import 'package:flutter/material.dart';

import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/core/constants/route_names.dart';

Widget bottomNav(BuildContext context, int active) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final activeColor = isDark ? const Color(0xFF2EB8E6) : BrandColors.primary;
  final inactiveColor = isDark
      ? const Color(0xFFACC0CC)
      : const Color(0xFF728A98);

  final items = <({String label, IconData icon, String routeName})>[
    (label: 'Home', icon: Icons.home_filled, routeName: RouteNames.activity),
    (
      label: 'Discover',
      icon: Icons.explore_outlined,
      routeName: RouteNames.discover,
    ),
    (
      label: 'Quran',
      icon: Icons.menu_book_outlined,
      routeName: RouteNames.quran,
    ),
    (
      label: 'Prayer',
      icon: Icons.calendar_month_outlined,
      routeName: RouteNames.prayerTimes,
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
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xEA0F1F29), Color(0xF4112029)]
            : const [Color(0xF8FFFFFF), Color(0xF0F8FCFF)],
      ),
      border: Border(
        top: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xC8D2E2ED),
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? const Color(0x30000000) : const Color(0x120E3853),
          blurRadius: 14,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isActive = index == active;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTapItem(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: isDark ? 0.2 : 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(
                      color: activeColor.withValues(
                        alpha: isDark ? 0.42 : 0.34,
                      ),
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: isActive ? 22 : 20,
                  color: isActive ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
