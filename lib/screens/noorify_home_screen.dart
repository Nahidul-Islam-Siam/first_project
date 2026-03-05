import 'package:flutter/material.dart';

import '../app/brand_colors.dart';
import '../app/route_names.dart';

class NoorifyHomeScreen extends StatelessWidget {
  const NoorifyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const quickActions = <_QuickActionData>[
      _QuickActionData(
        label: 'Daily Activity',
        icon: Icons.checklist_rounded,
        routeName: RouteNames.activity,
      ),
      _QuickActionData(
        label: 'Quran',
        icon: Icons.menu_book_rounded,
        routeName: RouteNames.quran,
      ),
      _QuickActionData(
        label: 'Qibla Compass',
        icon: Icons.explore_rounded,
        routeName: RouteNames.prayerCompass,
      ),
      _QuickActionData(
        label: 'Preferences',
        icon: Icons.settings_rounded,
        routeName: RouteNames.preferences,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F8F5), Color(0xFFE8F1EE)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _BrandHeader(),
              const SizedBox(height: 18),
              _AyahPlaceholderCard(),
              const SizedBox(height: 22),
              Text(
                'Quick Start',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BrandColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: quickActions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.95,
                ),
                itemBuilder: (context, index) {
                  final action = quickActions[index];
                  return _ActionTile(action: action);
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(RouteNames.preview),
                icon: const Icon(Icons.design_services_rounded),
                label: const Text('Open UI Preview Screens'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BrandColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BrandColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1B0A5A4A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [BrandColors.primaryDark, BrandColors.primary],
              ),
            ),
            child: const Icon(
              Icons.mosque_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Noorify',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: BrandColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your daily Islamic companion',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BrandColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahPlaceholderCard extends StatelessWidget {
  const _AyahPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: BrandColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: BrandColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Reflection',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: BrandColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bismillahir Rahmanir Rahim',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: BrandColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your day with remembrance, prayer, and gratitude.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BrandColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _QuickActionData action;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => Navigator.of(context).pushNamed(action.routeName),
      icon: Icon(action.icon),
      label: Text(action.label, maxLines: 2, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.routeName,
  });

  final String label;
  final IconData icon;
  final String routeName;
}
