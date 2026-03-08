import 'package:flutter/material.dart';

import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/features/dua/models/dua_item.dart';
import 'package:first_project/features/dua/services/dua_service.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  final DuaService _duaService = DuaService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  String _query = '';
  String _selectedCategory = 'all';
  List<DuaItem> _duas = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadDuas();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  Future<void> _loadDuas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final duas = await _duaService.loadDuas();
      if (!mounted) return;
      setState(() {
        _duas = duas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<String> get _categories {
    final set = <String>{};
    for (final dua in _duas) {
      if (dua.category.trim().isEmpty) continue;
      set.add(dua.category);
    }
    final values = set.toList(growable: false)..sort();
    return ['all', ...values];
  }

  List<DuaItem> get _filteredDuas {
    final filteredByCategory = _duas.where((item) {
      if (_selectedCategory == 'all') return true;
      return item.category == _selectedCategory;
    });

    if (_query.isEmpty) return filteredByCategory.toList(growable: false);

    return filteredByCategory
        .where((item) {
          return item.id.toString().contains(_query) ||
              item.titleEn.toLowerCase().contains(_query) ||
              item.titleBn.toLowerCase().contains(_query) ||
              item.arabic.contains(_query) ||
              item.english.toLowerCase().contains(_query) ||
              item.bangla.toLowerCase().contains(_query) ||
              item.reference.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  String _categoryLabel(String value) {
    switch (value) {
      case 'all':
        return 'All';
      case 'morning_evening':
        return 'Morning/Evening';
      case 'sleep':
        return 'Sleep';
      case 'food':
        return 'Food';
      case 'travel':
        return 'Travel';
      case 'prayer':
        return 'Prayer';
      case 'protection':
        return 'Protection';
      case 'forgiveness':
        return 'Forgiveness';
      case 'sickness':
        return 'Sickness';
      case 'family':
        return 'Family';
      default:
        return 'General';
    }
  }

  void _openDuaDetails(DuaItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titleBn.isNotEmpty ? item.titleBn : item.titleEn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.titleEn,
                  style: const TextStyle(
                    fontSize: 12,
                    color: BrandColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BrandColors.tintBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.arabic,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'English',
                  style: TextStyle(
                    fontSize: 12,
                    color: BrandColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.english,
                  style: const TextStyle(
                    fontSize: 14,
                    color: BrandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bangla',
                  style: TextStyle(
                    fontSize: 12,
                    color: BrandColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.bangla,
                  style: const TextStyle(
                    fontSize: 14,
                    color: BrandColors.textPrimary,
                  ),
                ),
                if (item.reference.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Reference',
                    style: TextStyle(
                      fontSize: 12,
                      color: BrandColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.reference,
                    style: const TextStyle(
                      fontSize: 13,
                      color: BrandColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTapPlay(DuaItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dua audio playback integration is next.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDuas;
    final glass = NoorifyGlassTheme(context);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: NoorifyGlassCard(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  radius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Hisnul Muslim Duas',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: glass.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: glass.isDark
                                  ? const Color(0x331FD5C0)
                                  : const Color(0x1F1EA8B8),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: glass.glassBorder),
                            ),
                            child: Text(
                              '${filtered.length}/${_duas.length}',
                              style: TextStyle(
                                color: glass.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Read, search, and save dua references',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: glass.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: glass.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search by title, meaning, reference',
                          hintStyle: TextStyle(color: glass.textMuted),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: glass.textMuted,
                          ),
                          filled: true,
                          fillColor: glass.isDark
                              ? const Color(0x4412272E)
                              : const Color(0xECFFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: glass.glassBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: glass.glassBorder),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_isLoading && _error == null)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final value = _categories[index];
                      final selected = value == _selectedCategory;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(_categoryLabel(value)),
                        selectedColor: glass.isDark
                            ? const Color(0x331FD5C0)
                            : const Color(0x261EA8B8),
                        checkmarkColor: glass.accent,
                        side: BorderSide(
                          color: selected ? glass.accent : glass.glassBorder,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? glass.accent : glass.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedCategory = value),
                      );
                    },
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: glass.accent),
                      )
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: glass.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: glass.accent,
                                  foregroundColor: glass.isDark
                                      ? const Color(0xFF032F35)
                                      : Colors.white,
                                ),
                                onPressed: _loadDuas,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final hasAudio = (item.audio ?? '').trim().isNotEmpty;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openDuaDetails(item),
                            child: NoorifyGlassCard(
                              radius: BorderRadius.circular(16),
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: glass.isDark
                                              ? const Color(0x331FD5C0)
                                              : const Color(0x221EA8B8),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '#${item.id}',
                                          style: TextStyle(
                                            color: glass.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _categoryLabel(item.category),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: glass.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton.filledTonal(
                                        tooltip: hasAudio
                                            ? 'Play audio'
                                            : 'No audio yet',
                                        onPressed: hasAudio
                                            ? () => _onTapPlay(item)
                                            : null,
                                        style: IconButton.styleFrom(
                                          backgroundColor: glass.isDark
                                              ? const Color(0x3316383E)
                                              : const Color(0x221EA8B8),
                                          foregroundColor: glass.accent,
                                        ),
                                        icon: const Icon(
                                          Icons.play_arrow_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.titleBn.isNotEmpty
                                        ? item.titleBn
                                        : item.titleEn,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: glass.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    item.titleEn,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: glass.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.arabic,
                                    textDirection: TextDirection.rtl,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: glass.textPrimary,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.english,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: glass.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              bottomNav(context, 1),
            ],
          ),
        ),
      ),
    );
  }
}
