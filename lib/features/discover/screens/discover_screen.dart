import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  bool _looksMojibake(String value) {
    for (final unit in value.codeUnits) {
      if (unit == 0x00C3 ||
          unit == 0x00C2 ||
          unit == 0x00E0 ||
          unit == 0x00D8 ||
          unit == 0x00D9 ||
          unit == 0x00D0 ||
          unit == 0x00E2) {
        return true;
      }
    }
    return false;
  }

  String _repairMojibake(String value) {
    var output = value;
    for (var i = 0; i < 2; i++) {
      if (!_looksMojibake(output)) break;
      try {
        output = utf8.decode(latin1.encode(output));
      } catch (_) {
        break;
      }
    }
    return output;
  }

  bool _containsBangla(String value) {
    return RegExp(r'[\u0980-\u09FF]').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguageNotifier,
      builder: (context, language, _) {
        final isBangla = language == AppLanguage.bangla;
        final glass = NoorifyGlassTheme(context);

        String t(String english, String bangla) {
          if (!isBangla) return english;
          final repaired = _repairMojibake(bangla);
          if (_looksMojibake(repaired)) return english;
          return _containsBangla(repaired) ? repaired : english;
        }

        void openRoute(String route) {
          Navigator.of(context).pushNamed(route);
        }

        return Scaffold(
          backgroundColor: glass.bgBottom,
          body: NoorifyGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      children: [
                        NoorifyGlassCard(
                          radius: BorderRadius.circular(28),
                          padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t(
                                            'Islamic Knowledge Hub',
                                            'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã…Â¾ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨ ÃƒÂ Ã‚Â¦Ã‚Â­ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¡ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°',
                                          ),
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: glass.textPrimary,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Asmaul Husna | Hadith | Dua',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: glass.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    onPressed: () =>
                                        openRoute(RouteNames.preferences),
                                    style: IconButton.styleFrom(
                                      backgroundColor: glass.isDark
                                          ? const Color(0x332EB8E6)
                                          : const Color(0x221EA8B8),
                                      foregroundColor: glass.accent,
                                    ),
                                    icon: const Icon(Icons.settings_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 120,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: glass.accent.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        NoorifyGlassCard(
                          radius: BorderRadius.circular(18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: TextField(
                            style: TextStyle(color: glass.textPrimary),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: glass.textMuted,
                              ),
                              hintText: t(
                                'Search for resources...',
                                'ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¸ ÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚ÂÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨...',
                              ),
                              hintStyle: TextStyle(color: glass.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SectionTitle(
                          title: t(
                            'Names of Allah',
                            'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â²ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â®',
                          ),
                        ),
                        _FeatureCard(
                          title: t(
                            'Ar-Rahman',
                            'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚Â°-ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨',
                          ),
                          subtitle: t(
                            'The Most Merciful',
                            'ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â® ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â£ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â§Ã…Â¸',
                          ),
                          detail: t(
                            'Featured Name of the Day',
                            'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã…Â¡ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¤ ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â®',
                          ),
                          badge: '1',
                          trailingText: 'Ar-Rahman',
                          icon: Icons.menu_book_rounded,
                          onTap: () => openRoute(RouteNames.asma),
                        ),
                        const SizedBox(height: 10),
                        _SectionTitle(
                          title: t(
                            'Hadith Collection',
                            'ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¸ ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¦Ã¢â‚¬â€ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¹',
                          ),
                        ),
                        _FeatureCard(
                          title: t(
                            'Hadith 1',
                            'ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¸ ÃƒÂ Ã‚Â§Ã‚Â§',
                          ),
                          subtitle: t(
                            'Collection: Bukhari',
                            'ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¦Ã¢â‚¬â€ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¹: ÃƒÂ Ã‚Â¦Ã‚Â¬ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã‚Â¿',
                          ),
                          detail: t(
                            'Read short authentic hadith references',
                            'ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¹ ÃƒÂ Ã‚Â¦Ã‚Â¹ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã‚Â¸ÃƒÂ Ã‚Â¦Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â·ÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¤ ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â«ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¸ ÃƒÂ Ã‚Â¦Ã‚ÂªÃƒÂ Ã‚Â§Ã…â€œÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨',
                          ),
                          icon: Icons.auto_stories_rounded,
                          onTap: () => openRoute(RouteNames.hadith),
                        ),
                        const SizedBox(height: 10),
                        _SectionTitle(
                          title: t(
                            'Dua & Zikr',
                            'ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â§Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â¦Ã¢â‚¬Å“ ÃƒÂ Ã‚Â¦Ã…â€œÃƒÂ Ã‚Â¦Ã‚Â¿ÃƒÂ Ã‚Â¦Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¦Ã‚Â°',
                          ),
                        ),
                        _FeatureCard(
                          title: t(
                            'Dua 1',
                            'ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â§Ã…Â¸ÃƒÂ Ã‚Â¦Ã‚Â¾ ÃƒÂ Ã‚Â§Ã‚Â§',
                          ),
                          subtitle: t(
                            'Before Sleeping',
                            'ÃƒÂ Ã‚Â¦Ã‹Å“ÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â®ÃƒÂ Ã‚Â¦Ã‚Â¾ÃƒÂ Ã‚Â¦Ã‚Â¨ÃƒÂ Ã‚Â§Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¦Ã‚Â° ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã¢â‚¬â€ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡',
                          ),
                          detail: 'Allahumma bismika amutu wa ahya',
                          icon: Icons.volunteer_activism_rounded,
                          onTap: () => openRoute(RouteNames.dua),
                        ),
                        const SizedBox(height: 12),
                        _SectionTitle(
                          title: t(
                            'Explore More',
                            'ÃƒÂ Ã‚Â¦Ã¢â‚¬Â ÃƒÂ Ã‚Â¦Ã‚Â°ÃƒÂ Ã‚Â¦Ã¢â‚¬Å“ ÃƒÂ Ã‚Â¦Ã‚Â¦ÃƒÂ Ã‚Â§Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¦Ã¢â‚¬â€œÃƒÂ Ã‚Â§Ã‚ÂÃƒÂ Ã‚Â¦Ã‚Â¨',
                          ),
                        ),
                        GridView.count(
                          crossAxisCount: 3,
                          childAspectRatio: 1.1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _QuickTile(
                              title: t(
                                'Prophet Stories',
                                'Ã Â¦Â¨Ã Â¦Â¬Ã Â§â‚¬-Ã Â¦Â°Ã Â¦Â¾Ã Â¦Â¸Ã Â§ÂÃ Â¦Â² Ã Â¦â€¢Ã Â¦Â¾Ã Â¦Â¹Ã Â¦Â¿Ã Â¦Â¨Ã Â§â‚¬',
                              ),
                              icon: Icons.account_balance_rounded,
                              onTap: () => openRoute(RouteNames.hadith),
                            ),
                            _QuickTile(
                              title: t(
                                'Islamic Calendar',
                                'Ã Â¦â€¡Ã Â¦Â¸Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¯Ã Â¦Â¾Ã Â¦Â²Ã Â§â€¡Ã Â¦Â¨Ã Â§ÂÃ Â¦Â¡Ã Â¦Â¾Ã Â¦Â°',
                              ),
                              icon: Icons.calendar_month_rounded,
                              onTap: () => openRoute(RouteNames.prayerCompass),
                            ),
                            _QuickTile(
                              title: t(
                                'Quran Quiz',
                                'Ã Â¦â€¢Ã Â§ÂÃ Â¦Â°Ã Â¦â€ Ã Â¦Â¨ Ã Â¦â€¢Ã Â§ÂÃ Â¦â€¡Ã Â¦Å“',
                              ),
                              icon: Icons.quiz_rounded,
                              onTap: () => openRoute(RouteNames.quran),
                            ),
                            _QuickTile(
                              title: t(
                                'Tasbih Counter',
                                'Ã Â¦Â¤Ã Â¦Â¾Ã Â¦Â¸Ã Â¦Â¬Ã Â¦Â¿Ã Â¦Â¹ Ã Â¦â€¢Ã Â¦Â¾Ã Â¦â€°Ã Â¦Â¨Ã Â§ÂÃ Â¦Å¸Ã Â¦Â¾Ã Â¦Â°',
                              ),
                              icon: Icons.countertops_rounded,
                              onTap: () => openRoute(RouteNames.tasbih),
                            ),
                            _QuickTile(
                              title: t(
                                'Prayer Times',
                                'Ã Â¦Â¨Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¾Ã Â¦Å“Ã Â§â€¡Ã Â¦Â° Ã Â¦â€œÃ Â§Å¸Ã Â¦Â¾Ã Â¦â€¢Ã Â§ÂÃ Â¦Â¤',
                              ),
                              icon: Icons.mosque_rounded,
                              onTap: () => openRoute(RouteNames.prayerCompass),
                            ),
                            _QuickTile(
                              title: t(
                                'Islamic Tips',
                                'Ã Â¦â€¡Ã Â¦Â¸Ã Â¦Â²Ã Â¦Â¾Ã Â¦Â®Ã Â¦Â¿Ã Â¦â€¢ Ã Â¦Å¸Ã Â¦Â¿Ã Â¦ÂªÃ Â¦Â¸',
                              ),
                              icon: Icons.lightbulb_rounded,
                              onTap: () => openRoute(RouteNames.about),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  bottomNav(context, 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 5),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: glass.textSecondary,
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.onTap,
    this.badge,
    this.trailingText,
  });

  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: NoorifyGlassCard(
        radius: BorderRadius.circular(18),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: glass.isDark
                    ? const Color(0x332EB8E6)
                    : const Color(0x221EA8B8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: glass.accent, size: 26),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 27 / 1.35,
                            fontWeight: FontWeight.w700,
                            color: glass.textPrimary,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: glass.isDark
                                ? const Color(0x332EB8E6)
                                : const Color(0x221EA8B8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 12,
                              color: glass.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24 / 1.35,
                      color: glass.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: glass.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 8),
              Text(
                trailingText!,
                style: TextStyle(
                  fontSize: 19,
                  color: glass.accentSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: NoorifyGlassCard(
        radius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: glass.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            Icon(icon, size: 20, color: glass.accentSoft),
          ],
        ),
      ),
    );
  }
}
